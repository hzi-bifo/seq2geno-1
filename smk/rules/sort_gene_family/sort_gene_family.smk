rule sort_gene_family :
    # compute family-wise alignments
    input:
        roary_gpa= lambda wildcards: os.path.join(TMP_D,
            SOFTWARE['gene_sorter'],'gene_presence_absence.csv'),
        gene_dna_seqs= lambda wildcards: [os.path.join(TMP_D, strain,
            SOFTWARE['assembler'], SOFTWARE['annotator'], 
            'de_novo.ffn') for strain in DNA_READS.index.values.tolist()]
    output:
        aln= dynamic(os.path.join(TMP_D, 'extracted_proteins_nt', '{fam}.aln'))
    params:
        CORES= CORES,
        MIN_SAMPLES= int(len(DNA_READS.index.values.tolist())/2),
        STRAINS= DNA_READS.index.values.tolist(),
        TMP_D= TMP_D+'/extracted_proteins_nt'
    script: 'makeGroupAln.py'

