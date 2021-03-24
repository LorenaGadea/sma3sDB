library(DBI)

pw <- "weRI34"
dbConn <- dbConnect(RPostgres::Postgres(), dbname = "dbsma3s",
                    host = "localhost", port = 5432,
                    user = "master", password = pw)
rm(pw)

insertSourceTable<-function(dbConn,tableName,inputDf, ...){
    str(tableName)
    if(length(inputDf)!= 0 ){
        if(nrow(inputDf)>0){
            sqlSentence<-paste(sqlAppendTable(dbConn,tableName,inputDf,row.names=FALSE),"ON CONFLICT DO NOTHING",sep=" ")
            rs<-dbSendStatement(dbConn, sqlSentence)
            dbClearResult(rs)
        }
    }
}

tables<-c("protein_gop","protein_gof","protein_goc","protein_gene","protein_enzyme",
          "protein_pathway","protein_score","protein_description", "protein_go_slim","protein_keyword")

fileConn <- file("uniref90.annot",open="r")
while (TRUE){
    annotDf<-read.csv(fileConn,sep="\t",header=FALSE,stringsAsFactors=FALSE,row.names=NULL,
                      col.names=c("id","score","gene","description","enzyme","go","keyword","pathway","goslim"),
                      colClasses=c("character","character","character","character","character","character","character","character","character"),
                      quote="",
                      nrows=1000)
    
    ## Exit condition
    if(is.data.frame(annotDf) && nrow(annotDf)==0){
        break
    }
    ## Extract ID column
    id<-annotDf[,"id"]
    
    ## GENE NAME 
    geneVecList<-strsplit(annotDf[complete.cases(annotDf[,"gene"]),"gene"],";") 
    idVec<-rep(annotDf[complete.cases(annotDf[,"gene"]),"id"],lengths(geneVecList)) ## rep() crear un vector repitiendo
    geneRawVec<-unlist(geneVecList)
    geneGrepBoolean<-grepl("(.*)\\{(ECO:.*)\\}",geneRawVec)
    geneVec<-ifelse(geneGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\1",geneRawVec),geneRawVec)
    geneEcoVec<-ifelse(geneGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\2",geneRawVec),rep(NA,length(geneRawVec)))
    ## Don't build dataframe if empty
    if(length(geneVec)!=0){
        geneDf=unique(data.frame(protein_id=idVec, gene=geneVec, eco=geneEcoVec))
        ## Source table
        insertSourceTable(dbConn,"gene",geneDf[,"gene",drop=FALSE])
        ## Relation table
        insertSourceTable(dbConn,"protein_gene",geneDf,append=TRUE,row.names=FALSE)
        ## Save mem.
        rm(geneVecList)
        rm(geneVec)
        rm(idVec)
        rm(geneDf)
    }



    ## DESCRIPTION
    descriptionVecList<-strsplit(annotDf[complete.cases(annotDf[,"description"]),"description"],";")
    descriptionRawVec<-unlist(descriptionVecList)
    descriptionGrepBoolean<-grepl("(.*)\\{(ECO:.*)\\}",descriptionRawVec)
    descriptionVec<-ifelse(descriptionGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\1",descriptionRawVec),descriptionRawVec)
    descriptionEcoVec<-ifelse(descriptionGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\2",descriptionRawVec),rep(NA,length(descriptionRawVec)))
    idVec<-rep(annotDf[complete.cases(annotDf[,"description"]),"id"],lengths(descriptionVecList))

    if(length(descriptionVec)!=0){
        descriptionDf<-unique(data.frame(id=idVec, description=descriptionVec, eco=descriptionEcoVec))
        insertSourceTable(dbConn,"description",descriptionDf[,"description",drop=FALSE])
        insertSourceTable(dbConn,"protein_description",descriptionDf,append=TRUE,row.names=FALSE)
        rm(descriptionVecList)
        rm(descriptionRawVec)
        rm(descriptionVec)
        rm(descriptionEcoVec)
        rm(idVec)
        rm(descriptionDf)
    }

    
    ## ENZYME
    enzymeVecList<-strsplit(annotDf[complete.cases(annotDf[,"enzyme"]),"enzyme"],";")
    enzymeRawVec<-unlist(enzymeVecList)
    enzymeGrepBoolean<-grepl("(.*)\\{(ECO:.*)\\}",enzymeRawVec)
    enzymeVec<-ifelse(enzymeGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\1",enzymeRawVec),enzymeRawVec)
    enzymeEcoVec<-ifelse(enzymeGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\2",enzymeRawVec),rep(NA,length(enzymeRawVec)))
    idVec<-rep(annotDf[complete.cases(annotDf[,"enzyme"]),"id"],lengths(enzymeVecList))
    if(length(enzymeVec)!=0){
        enzymeDf<-unique(data.frame(protein_id=idVec, enzyme=enzymeVec, eco=enzymeEcoVec))
        insertSourceTable(dbConn,"enzyme",enzymeDf[,"enzyme",drop=FALSE])
        insertSourceTable(dbConn,"protein_enzyme",enzymeDf,append=TRUE,row.names=FALSE)
        rm(enzymeVecList)
        rm(enzymeRawVec)
        rm(enzymeVec)
        rm(enzymeEcoVec)
        rm(idVec)
        rm(enzymeDf)
    }
    
    ## SCORE (Two values)
    mixedScoreVec<-annotDf[complete.cases(annotDf[,"score"]),"score"]
    score1Vec<-gsub("^(.*?),(.*)", "\\1",mixedScoreVec)
    score2Vec<-gsub("^(.*?),(.*)", "\\2",mixedScoreVec)
    idVec<-annotDf[complete.cases(annotDf[,"score"]),"id"]
    scoreDf<-unique(data.frame(protein_id=idVec, score1=score1Vec, score2=score2Vec))
    insertSourceTable(dbConn,"protein_score",scoreDf,append=TRUE,row.names=FALSE)
    rm(mixedScoreVec)
    rm(score1Vec)
    rm(score2Vec)
    rm(idVec)
    rm(scoreDf)
    
    ## GO 
    goRawVecList<-strsplit(annotDf[complete.cases(annotDf[,"go"]),"go"],";")
    goRawVec<-unlist(goRawVecList)
    goIdVec<-gsub("(.*)\\{.*\\}","\\1",goRawVec)
    goTypeVec<-gsub(".*\\{([CFP]):.*\\}","\\1",goRawVec)
    goNameAndEvidenceVec<-gsub(".*\\{[CFP]:(.*)\\}","\\1",goRawVec)
    ##str(goNameAndEvidenceVec)
    goNameVec<-ifelse(grepl("(.*):.*",goNameAndEvidenceVec),gsub("(.*):.*","\\1",goNameAndEvidenceVec),goNameAndEvidenceVec)
    goEvidenceVec<-ifelse(grepl(".*:(.*)",goNameAndEvidenceVec),gsub(".*:(.*)","\\1",goNameAndEvidenceVec),rep(NA,length(goNameAndEvidenceVec)))
    ##str(goEvidenceVec)
    idVec<-rep(annotDf[complete.cases(annotDf[,"go"]),"id"],lengths(goRawVecList))
    if(length(goIdVec)!=0){
        goDf<-unique(data.frame(protein_id=idVec, go=goIdVec, type= goTypeVec, go_name=goNameVec, evidence_code=goEvidenceVec))
        ## Split mixed dataframe in three separated by type
        x<-split(goDf,goDf$type)     
        
        insertSourceTable(dbConn,"goc",x[["C"]][,c("go","go_name")])
        insertSourceTable(dbConn,"gop",x[["P"]][,c("go","go_name")])
        insertSourceTable(dbConn,"gof",x[["F"]][,c("go","go_name")])
        if(length(x[["C"]])>0){
            insertSourceTable(dbConn,"protein_goc",unique(x[["C"]][,c("protein_id","go","evidence_code")]),append=TRUE,row.names=FALSE)
        }
        if(length(x[["P"]])>0){
            insertSourceTable(dbConn,"protein_gop",unique(x[["P"]][,c("protein_id","go","evidence_code")]),append=TRUE,row.names=FALSE)
        }
        if(length(x[["F"]])>0){
            insertSourceTable(dbConn,"protein_gof",unique(x[["F"]][,c("protein_id","go","evidence_code")]),append=TRUE,row.names=FALSE)
        }      
        rm(goRawVecList)
        rm(goIdVec)
        rm(goTypeVec)
        rm(goNameVec)
        rm(goEvidenceVec)
        rm(goDf)
        rm(x)
    }

    ##KEYWORD
    keywordVecList<-strsplit(annotDf[complete.cases(annotDf[,"keyword"]),"keyword"],";")
    keywordRawVec<-unlist(keywordVecList)
    keywordGrepBoolean<-grepl("(.*)\\{(ECO:.*)\\}",keywordRawVec)
    keywordVec<-ifelse(keywordGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\1",keywordRawVec),keywordRawVec)
    keywordEcoVec<-ifelse(keywordGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\2",keywordRawVec),rep(NA,length(keywordRawVec)))
    idVec<-rep(annotDf[complete.cases(annotDf[,"keyword"]),"id"],lengths(keywordVecList))
    if(length(keywordVec)!=0){
        keywordDf<-unique(data.frame(protein_id=idVec, keyword=keywordVec, eco=keywordEcoVec))
        insertSourceTable(dbConn,"keyword",keywordDf[,"keyword",drop=FALSE])
        insertSourceTable(dbConn,"protein_keyword",keywordDf,append=TRUE,row.names=FALSE)
        rm(keywordVecList)
        rm(keywordRawVec)
        rm(keywordVec)
        rm(keywordEcoVec)
        rm(idVec)
        rm(keywordDf)
    }

    
    ## PATHWAY
    pathwayVecList<-strsplit(annotDf[complete.cases(annotDf[,"pathway"]),"pathway"],";")
    pathwayRawVec<-unlist(pathwayVecList)
    pathwayGrepBoolean<-grepl("(.*)\\{(ECO:.*)\\}",pathwayRawVec)
    pathwayVec<-ifelse(pathwayGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\1",pathwayRawVec),pathwayRawVec)
    pathwayEcoVec<-ifelse(pathwayGrepBoolean,gsub("(.*)\\{(ECO:.*)\\}","\\2",pathwayRawVec),rep(NA,length(pathwayRawVec)))
    idVec<-rep(annotDf[complete.cases(annotDf[,"pathway"]),"id"],lengths(pathwayVecList))
    if(length(pathwayVec)!=0){
        pathwayDf<-unique(data.frame(protein_id=idVec, pathway=pathwayVec, eco=pathwayEcoVec))
        insertSourceTable(dbConn,"pathway",pathwayDf[,"pathway",drop=FALSE])
        insertSourceTable(dbConn,"protein_pathway",pathwayDf,append=TRUE,row.names=FALSE)
        rm(pathwayVecList)
        rm(pathwayRawVec)
        rm(pathwayVec)
        rm(pathwayEcoVec)
        rm(idVec)
        rm(pathwayDf)
    }

    
    ## GO SLIM
    goslimVecList<-strsplit(annotDf[complete.cases(annotDf[,"goslim"]),"goslim"],";")
    goslimVec<-unlist(goslimVecList)
    idVec<-rep(annotDf[complete.cases(annotDf[,"goslim"]), "id"], lengths(goslimVecList))
    if(length(goslimVec)!=0){
        goslimDf<-unique(data.frame(protein_id=idVec, go_slim=goslimVec))
        insertSourceTable(dbConn,"go_slim",goslimDf[,"go_slim",drop=FALSE])
        insertSourceTable(dbConn,"protein_go_slim",goslimDf,append=TRUE,row.names=FALSE)
        rm(goslimVecList)
        rm(goslimDf)
        rm(goslimVec)
        rm(idVec)
    }
    str('Cycle completed')
}
str('Data successfully charged')
close(fileConn)
dbDisconnect(dbConn)
