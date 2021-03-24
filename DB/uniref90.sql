
/*Uniref90.fasta*/
create table protein (
    id character varying primary key,
    protein_sequence character varying
);

/*uniref90.annot*/
/*Description*/
create table description (
  description character varying primary key  
);

/*Protein description*/
create table protein_description (
  id character varying references protein(id) on update cascade on delete cascade,
  description character varying references description(description) on update cascade on delete cascade,
  eco character varying,
  quality boolean,
  primary key (id,description)  
);

/*Protein Score*/
create table protein_score (
  protein_id character varying primary key references protein(id) on update cascade on delete cascade,
  score1 integer,
  score2 integer  
);

/*GENE*/
create table gene (
  gene character varying primary key
);

/*GENE-PROTEIN RELATION*/
create table protein_gene (
  protein_id character varying not null references protein(id) on update cascade on delete cascade,
  gene character varying not null references gene(gene) on update cascade on delete cascade,
  eco character varying,
  quality boolean,
  primary key (protein_id, gene)
);

/*GO TABLES*/
create table gop (
  go character varying primary key,
  go_name character varying
);

create table goc (
  go character varying primary key,
  go_name character varying
);

create table gof (
  go character varying primary key,
  go_name character varying
);

/*GO-PROTEINS RELATION TABLES */
create table protein_gop (
  protein_id character varying not null references protein(id) on update cascade on delete cascade,
  go character varying not null references gop(go) on update cascade on delete cascade,
  evidence_code character varying,
  primary key (go,protein_id)
);

create table protein_goc (
  protein_id character varying not null references protein(id) on update cascade on delete cascade,
  go character varying not null references goc(go) on update cascade on delete cascade,
  evidence_code character varying,
  primary key (go,protein_id)
);

create table protein_gof (
  protein_id character varying not null references protein(id) on update cascade on delete cascade,
  go character varying not null references gof(go) on update cascade on delete cascade,
  evidence_code character varying,
  primary key (go,protein_id)
);


/*KEYWORD*/
create table keyword (
  keyword character varying primary key
);

/*KEYWORD-PROTEIN RELATION*/
create table protein_keyword (
  protein_id character varying not null references protein(id) on update cascade on delete cascade,
  keyword character varying not null references keyword(keyword) on update cascade on delete cascade,
  eco character varying,
  quality boolean,
  primary key (keyword,protein_id)
);

/*PATHWAY*/
create table pathway (
  pathway character varying primary key
);

/*PATHWAY-PROTEIN RELATION*/
create table protein_pathway (
  protein_id character varying not null references protein(id) on update cascade on delete cascade,
  pathway character varying not null references pathway(pathway) on update cascade on delete cascade,
  eco character varying,
  quality boolean,  
  primary key (pathway,protein_id)
);

/*ENZYME*/
create table enzyme (
  enzyme character varying primary key
);

/*ENZYME-PROTEIN RELATION*/
create table protein_enzyme (
  protein_id character varying not null references protein(id) on update cascade on delete cascade,
  enzyme character varying not null references enzyme(enzyme) on update cascade on delete cascade,
  eco character varying,
  quality boolean, 
  primary key (enzyme,protein_id)
);

/*GO SLIM*/
create table go_slim (
  go_slim character varying primary key
);

/*GO SLIM-PROTEIN RELATION*/
create table protein_go_slim (
  protein_id character varying not null references protein(id) on update cascade on delete cascade,
  go_slim character varying not null references go_slim(go_slim) on update cascade on delete cascade,
  primary key (go_slim,protein_id)
);

/*Indexes*/
CREATE INDEX ON protein_goc(protein_id);
CREATE INDEX ON protein_gof(protein_id);
CREATE INDEX ON protein_gop(protein_id);
CREATE INDEX ON protein_go_slim(protein_id);
CREATE INDEX ON protein_description(id);
CREATE INDEX ON protein_gene(protein_id);
CREATE INDEX ON protein_pathway(protein_id);
CREATE INDEX ON protein_keyword(protein_id);
CREATE INDEX ON protein_enzyme(protein_id);



