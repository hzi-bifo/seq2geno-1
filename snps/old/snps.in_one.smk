## import a list
import pandas as pd
from snakemake.utils import validate

list_f= config['list_f']
#list_f= 'data/samples.10.dna_full.tsv'
dna_reads= {}
with open(list_f, 'r') as list_fh:
    for l in list_fh:
        d=l.strip().split('\t')
        dna_reads[d[0]]= d[1].split(',')

strains= list(dna_reads.keys())
#ref_fasta='Pseudomonas_aeruginosa_PA14.edit.fasta'
#ref_gbk='Pseudomonas_aeruginosa_PA14_ncRNA.gbk'
#annot_tab='Pseudomonas_aeruginosa_PA14_annotation_with_ncRNAs_07_2011_12genes.tab'
#r_annot='Pseudomonas_aeruginosa_PA14_12genes_R_annotation'
#snps_table='all_SNPs.tab'
#snps_aa_table='all_SNPs_final.tab'
#nonsyn_snps_aa_table='nonsyn_SNPs_final.tab'
#snps_aa_bin_mat='all_SNPs_final.bin.mat'
#nonsyn_snps_aa_bin_mat='nonsyn_SNPs_final.bin.mat'

ref_fasta=config['ref_fasta']
ref_gbk=config['ref_gbk']
annot_tab=config['annot_tab']
r_annot=config['r_annot']
snps_table=config['snps_table']
snps_aa_table=config['snps_aa_table']
nonsyn_snps_aa_table=config['nonsyn_snps_aa_table']
snps_aa_bin_mat=config['snps_aa_bin_mat']
nonsyn_snps_aa_bin_mat=config['nonsyn_snps_aa_bin_mat']

rule all:
    input:
        snps_aa_bin_mat,
        nonsyn_snps_aa_bin_mat

rule create_binary_table:
    input:
        snps_aa_table=snps_aa_table,
        nonsyn_snps_aa_table=nonsyn_snps_aa_table
    output:
        snps_aa_bin_mat=snps_aa_bin_mat,
        nonsyn_snps_aa_bin_mat=nonsyn_snps_aa_bin_mat
    run:
        import pandas as pd
        import re
        def tab_transform(tab_f):
            tab=pd.read_csv(tab_f, sep='\t', header= 0)
            target_columns=['gene', 'pos', 'ref', 'alt', 'ref aa','alt aa']
            tab['feat_name']=tab.apply(lambda r:
                '_'.join(r[target_columns].apply(lambda x: str(x)).tolist()), axis=1)
            mat=tab.set_index('feat_name').drop(target_columns, axis=1).transpose()
            mat=mat.applymap(lambda x: '1' if re.search('[0-9]+', str(x)) else '0')
            return(mat)
        all_mat=tab_transform(input.snps_aa_table)
        print(all_mat.shape)
        print(output.snps_aa_bin_mat)
        all_mat.to_csv(output.snps_aa_bin_mat, sep= '\t', index_label= '')
        print(output.snps_aa_bin_mat)
        nonsyn_mat=tab_transform(input.nonsyn_snps_aa_table)
        nonsyn_mat.to_csv(output.nonsyn_snps_aa_bin_mat, sep= '\t', index_label= '')
        

rule create_table:
    input:
        flt_vcf=expand('{strain}.flt.vcf', strain= strains),
        flatcount=expand('{strain}.flatcount', strain= strains),
        dict_file='dict.txt',
        ref_gbk=ref_gbk,
        annofile=annot_tab
    output:
        snps_table=snps_table,
        snps_aa_table=snps_aa_table,
        nonsyn_snps_aa_table=nonsyn_snps_aa_table
    conda: 'snps_tab_mapping.yml'
    shell:
        '''
        mutation_table.py -f {input.dict_file} -a {input.annofile} -o {output.snps_table}
        Snp2Amino.py -f {output.snps_table} -g {input.ref_gbk} -o {output.snps_aa_table}
        Snp2Amino.py -n non-syn -f {output.snps_table} -g {input.ref_gbk} \
-o {output.nonsyn_snps_aa_table}
        '''

rule isolate_dict:
    input:
        flt_vcf=expand('{strain}.flt.vcf', strain= strains),
        flatcount=expand('{strain}.flatcount', strain= strains)
    output:
        dict_file='dict.txt'
    threads:1
    wildcard_constraints:
        strain='^[^\/]+$'
    params:
        strains= strains
    run:
        import re
        import os
        ## list and check all required files
        try:
            empty_files= [f for f in input if os.path.getsize(f)==0]
            if len(empty_files) > 0:
                raise Exception('{} should not be empty'.format(
','.join(empty_files)))
        except Exception as e:
            sys.exit(str(e))
        
        with open(output[0], 'w') as out_fh:
            out_fh.write('\n'.join(params.strains))
        
rule my_samtools_SNP_pipeline:
    input:
        sam='{strain}.sam',
        reffile=ref_fasta
    output:
        bam='{strain}.bam',
        raw_bcf='{strain}.raw.bcf',
        flt_vcf='{strain}.flt.vcf'
    threads:1
    conda: 'snps_tab_mapping.yml'
    shell:
        """
        export PERL5LIB=$CONDA_PREFIX/lib/perl5/site_perl/5.22.0:\
$CONDA_PREFIX/lib/perl5/5.22.2:\
$CONDA_PREFIX/lib/perl5/5.22.2/x86_64-linux-thread-multi/:\
$PERL5LIB
        echo $PERL5LIB
        my_samtools_SNP_pipeline {wildcards.strain} {input.reffile} 0
        """
        
rule my_stampy_pipeline_PE:
    input:
        #infile1=strain_fq1,
        #infile2=strain_fq2,
        infile1=lambda wildcards: dna_reads[wildcards.strain][0],
        infile2=lambda wildcards: dna_reads[wildcards.strain][1],
        reffile=ref_fasta,
        ref_index_stampy=ref_fasta+'.stidx',
        ref_index_bwa=ref_fasta+'.bwt',
        annofile=annot_tab,
        Rannofile=r_annot
    output:
        sam='{strain}.sam',
        art='{strain}.art',
        sin='{strain}.sin',
        flatcount='{strain}.flatcount',
        rpg='{strain}.rpg',
        stat='{strain}.stats'
    threads:1
    conda: 'snps_tab_mapping.yml'
    shell:
        """
        export PERL5LIB=$CONDA_PREFIX/lib/perl5/5.22.2/x86_64-linux-thread-multi/:$PERL5LIB
        export PERL5LIB=$CONDA_PREFIX/lib/perl5/5.22.2:$PERL5LIB
        export PERL5LIB=$CONDA_PREFIX/lib/perl5/site_perl/5.22.0:$PERL5LIB
        my_stampy_pipeline_PE {wildcards.strain} {input.infile1} \
{input.infile2} {input.reffile} {input.annofile} {input.Rannofile} 2> {wildcards.strain}.log
        """

rule stampy_index_ref:
    input:
        reffile=ref_fasta
    output:
        ref_fasta+'.bwt',
        ref_fasta+'.stidx',
        ref_fasta+'.sthash'
    conda: 'snps_tab_mapping.yml'
    shell:
        '''
        stampy.py -G {input.reffile} {input.reffile}
        stampy.py -g {input.reffile} -H {input.reffile}
        bwa index -a bwtsw {input.reffile}
        '''