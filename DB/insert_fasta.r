
library(DBI)

pw <- "weRI34"
dbConn <- dbConnect(RPostgres::Postgres(), dbname = "dbsma3s",
                    host = "localhost", port = 5432,
                    user = "master", password = pw)
rm(pw)

## Initialice components
fastaHeader=""
fastaSequence=""
startSequenceBody=FALSE
insideSequenceBody=FALSE

## The .fasta file will be processed line by line
fileConn = file("uniref90.fasta", "r")
while ( TRUE ) {
    line = readLines(fileConn, n = 1)
    ## First line
    if ( length(line) == 0 ) {
	    if(insideSequenceBody){
            ##Insert value into db
            rs<-dbSendStatement(
                dbConn,                                 
                "INSERT INTO protein(id,protein_sequence) VALUES ($1,$2) ON CONFLICT DO NOTHING",
                params=list(
                    fastaHeader,
                    fastaSequence
                )
            )
            dbClearResult(rs)

            ##l Reset variables
            fastaHeader=""
            fastaSequence=""
            insideSequenceBody = FALSE
        }
        break
    }

    ## Next lines, find last protein
    if(startsWith(line, ">")){
        if(insideSequenceBody){
            rs<-dbSendStatement(
                dbConn,                                 
                "INSERT INTO protein(id,protein_sequence) VALUES ($1,$2) ON CONFLICT DO NOTHING",
                params=list(
                    fastaHeader,
                    fastaSequence
                )
            )
            dbClearResult(rs)
            fastaHeader=""
            fastaSequence=""
            insideSequenceBody = FALSE
        }
        ##Save id
        fastaHeader = gsub("^>([^\\s]*)", "\\1", line)
        startSequenceBody = TRUE
        next
    }
    if(startSequenceBody){
        startSequenceBody=FALSE
        insideSequenceBody=TRUE
    }
    if(insideSequenceBody){
        fastaSequence<-paste(fastaSequence, line, sep='')
    }
}
close(fileConn)


rs <- dbSendQuery(dbConn, "SELECT COUNT(*) as entrycount FROM protein")
dfEntryCount<-dbFetch(rs)
dbClearResult(rs)
entryCount<-dfEntryCount[1,"entrycount"]
rm(dfEntryCount)

print(sprintf("%i entries inserted.", entryCount))