rule find_best_tree:
    input:
        one_big_var_aln=TMP_D+'/OneBig.var.aln'
    output:
        tree=config['tree']
    params:
        RAXML= RAXML_EXE,
        PREFIX= 'OneBig.var',
        RESULT_D= RESULT_D,
        RAXML_OUTDIR= RESULT_D,
       	CORES= CORES
    shell:
        '{params[RAXML]} -T {params[CORES]} -w {params[RAXML_OUTDIR]} '
        '-m GTRGAMMA -s {input} -n {params[PREFIX]} -p 1 -N 1;' 
        'cp -s {params[RAXML_OUTDIR]}/RAxML_bestTree.{params[PREFIX]} {output}'

rule postprocess_alignment:
    input:
        one_big_aln='{TMP_D}/OneBig.aln'
    output:
        one_big_var_aln='{TMP_D}/OneBig.var.aln'
    shell:
        "trimal -st 1 -gt 1 -complementary -in {input} -out {output}"

rule create_coding_regions_aln:
### concatenate 
    input:
        cons_coding_seqs_every_strain=expand(
            "{TMP_D}/{strains}/{mapper}/cons.fa", 
            TMP_D= TMP_D, strains= STRAINS, mapper= 'bwa')
    output:
        one_big_aln='{TMP_D}/OneBig.aln'

    params:
        CORES=CORES, 
        TMP_D=TMP_D+"/families", 
        STRAINS=STRAINS 
    script: 'makeAlignment.py'
