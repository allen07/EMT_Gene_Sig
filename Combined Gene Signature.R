library('GSA')
library('GSEABase')
library('limma')

#WD <- "G:/R Workspace"
#WD <- "E:/Russell/Documents/GitHub/EMT_Gene_Sig"
WD <- "C:/Users/rwill127/Documents/GitHub/EMT_Gene_Sig"


setwd(WD)
liver <- read.csv("Liver Differential Genes.csv")
prostate <- read.csv("MycCaP Twist v Vector Gene Expression.csv")
lung <- read.csv("CRT_CR_results.csv")


liver.sym <- liver$Symbol
prostate.sym <- prostate$Symbol
lung.sym <- lung$Symbol


shared_genes <- intersect(liver.sym, intersect(lung.sym, prostate.sym))
#write.csv(shared_genes, "Liver Lung Prostate Shared Gene Sig.csv")

Eifbuild_table <- function(gene_list){
    full_table<-data.frame(row.names = gene_list)
    full_table$p.lung <- lung$adj.P.Val[which(unique(lung$Symbol)%in%gene_list)]
    full_table$fc.lung <- lung$logFC[which(unique(lung$Symbol)%in%gene_list)]
    full_table$p.liver <- liver$adj.P.Val[which(unique(liver$Symbol)%in%gene_list)]
    full_table$fc.liver <- liver$logFC[which(unique(liver$Symbol)%in%gene_list)]

    return(full_table)
}
info <- build_table(shared_genes)

lg_pr <- intersect(lung.sym, prostate.sym)
lg_lv <- intersect(liver.sym, lung.sym)
lv_pr <- intersect(liver.sym, prostate.sym)

same_sign <- function (x, y) {
  if((x>0 && y >0) || (x<0 && y <0)){
    return(TRUE)
  }
     else {
       return(FALSE)
     }
}

sign_filter <- function(list, table1, table2){
  return(mapply(same_sign,
         table1[which(unique(table1$Symbol) %in% list),"logFC"],
         table2[which(unique(table2$Symbol) %in% list),"logFC"]))
}




shared_genes <- lg_lv[which(sign_filter(lg_lv, lung, liver))]

shared_genes <- unique(append(shared_genes,
                              lv_pr[which(sign_filter(lv_pr, liver, prostate))]
                              )
                       )
build_table(shared_genes)

probes2genes <- as.list(mogene10sttranscriptclusterSYMBOL)
all_genes <- unique(unlist(probes2genes))

gsea_fisher <- function(sig_genes, geneset){
    geneset <- unlist(geneset)
    sig_in_set <- length(intersect(sig_genes, geneset))
    sig_not_in_set <- length(sig_genes) - sig_in_set
    not_sig_in_set <- length(geneset) - sig_in_set
    not_sig_not_in_set <- length(all_genes) - not_sig_in_set
    data <- matrix(c(sig_in_set, not_sig_in_set, sig_not_in_set, not_sig_not_in_set), nrow = 2)
    test <- fisher.test(data,alternative='greater')
    return(test$p.value)
}

subset_gsea_test <- function(sig_genes){
    gsea_tests <- p.adjust(sapply(GSEASets$genesets, function(x){gsea_fisher(names(sig_genes), x)}), method = "BH")
    names(gsea_tests) <- GSEASets$geneset.names
    sig_genesets <-gsea_tests[which(gsea_tests < .05)]
    return(sig_genesets)
}
GSEASets <- GSA.read.gmt('c2.all.v3.0.symbols.gmt')
subset_gsea_test(toupper(shared_genes))
