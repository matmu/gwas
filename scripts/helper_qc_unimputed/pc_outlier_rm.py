
import numpy as np
import pandas as pd
import subprocess
import argparse
import sys
import operator
import os
import glob

parser = argparse.ArgumentParser(
    description='Iterative outlier removal with PLINK 2.0.')

parser.add_argument('--plink2', default='plink',
                    type=str, help='Path to PLINK 2.0 (default: plink).')
parser.add_argument('--bfile', default=None, type=str,
                    help='PLINK binary file set prefix.')
parser.add_argument('--out', default='plink', type=str,
                    help='Output file path (default: plink).')
parser.add_argument('--npc-rm', default=10, type=int,
                    help='Number of PCs to remove outliers on (default: 10).')
parser.add_argument('--nsd-rm', default=6, type=int,
                    help='Number of SDs from mean define outliers (default: 6).')
parser.add_argument('--window-size', default=1000, type=int,
                    help='Window size (kb) in pruning step (default: 1000).')
parser.add_argument('--step-size', default=5, type=int,
                    help='Step size (variant ct) in pruning step (default: 5).')
parser.add_argument('--r2-thr', default=0.2, type=float,
                    help='R-square threshold in pruning step (default: 0.2).')
parser.add_argument('--keep-tmp', action="store_true",
                    help='Keep temporary files.')
parser.add_argument('--max-cycles', default=99, type=int,
                    help='Maximum number of cylces (default: 99).')


def _clone_plink_files(bfile, plink2, out):
    """Runs PLINK 2.0 cloning of bim/bed/fam files.
    """
    
    print('==================\nCreate result bim/bed/fam files...\n')
    try:
        subprocess.run('{} --bfile {} --make-bed --out {}'.format(plink2, bfile, out), shell=True, check=True)
    except:
        sys.exit('PLINK did not exit cleanly. Possible system resource allocation error. Check output\n\n')


def _find_outliers(pc_file, nsd):
    """Identifies genetic principal component outliers.
    """

    print('==================\nFind for outliers defined as {} SDs from the mean)...\n'.format(nsd))
    pcs = pd.read_csv(pc_file, sep=r'\s+', header=0)

    out_ids = []
    for p in pcs.drop(['#FID', 'IID'], axis=1).columns:
        
        pc = pcs[p]

        sd = np.std(pc)
        mu = np.mean(pc)
        out = (mu - pc).abs() > (nsd * sd)
        nout = out.sum()
       
        print(pc.name, ':', nout, 'outliers')

        out_ids = operator.add(out_ids, list(pcs[p].index.values[out]))

    return set(np.sort(out_ids))


def _remove_outliers(bfile, plink2, excl_file, out):
    """Runs PLINK 2.0 sample removing.
    """
    
    print('==================\nRemove outliers...\n')
    try:
       subprocess.run('{} --bfile {} --remove {} --make-bed --out {}'.format(plink2, bfile, excl_file, out), shell=True)
    except:
        sys.exit('PLINK did not exit cleanly. Possible system resource allocation error. Check output\n\n')


def _ld_pruning(bfile, plink2, winsize, stepsize, r2thr, out):
    """Runs PLINK 2.0 LD pruning.
    """
    
    print('==================\nPerform LD pruning...\n')
    try:
        subprocess.run('{} --bfile {} --indep-pairwise {} {} {} --out {}'.format(plink2, bfile, winsize, stepsize, r2thr, out), shell=True, check=True)
    except:
        sys.exit('PLINK did not exit cleanly. Possible system resource allocation error. Check output\n\n')

    return '{}.prune.in'.format(out)


def _pca(bfile, plink2, npc, var_file, out):
    """Runs PLINK 2.0 PCA and lists outliers along first 10 PCs.
    """

    print('==================\nCalculate PCs...\n')
    try:
        subprocess.run('{} --bfile {} --extract {} --pca {} --out {}'.format(plink2, bfile, var_file, npc, out),
                       shell=True, check=True)
    except:
        sys.exit('PLINK did not exit cleanly. Possible system resource allocation error. Check output\n\n')

    return '{}.eigenvec'.format(out)


if __name__ == '__main__':

    if len(sys.argv) == 1:
        parser.print_help(sys.stderr)
        sys.exit(1)
    args = parser.parse_args()
    
    max_cycles = args.max_cycles
    tmp_files = []

    var_file = _ld_pruning(bfile=args.bfile, plink2=args.plink2, winsize=args.window_size, stepsize=args.step_size, r2thr=args.r2_thr, out=args.bfile)
    pc_file = _pca(bfile=args.bfile, plink2=args.plink2, npc=args.npc_rm, var_file=var_file, out=args.bfile)
    cur_outlier_ids = _find_outliers(pc_file=pc_file, nsd=args.nsd_rm)

    tot_outliers = len(cur_outlier_ids)
    
    iteration = 0
    current_bfile = args.bfile
    while len(cur_outlier_ids) > 0:

        iteration += 1
        max_cycles -= 1

        new_bfile = '{}.iter{}'.format(args.out, iteration)
        excl_var_file = '{}.iter{}.excl'.format(args.out, iteration)

        tmp_files.append(new_bfile)


        # Remove samples
        pcs = pd.read_csv(pc_file, sep=r'\s+', header=0)
        (pcs[['#FID', 'IID']].iloc[list(cur_outlier_ids)].to_csv(excl_var_file, sep=' ', header=None, index=False))
        _remove_outliers(bfile=current_bfile, plink2=args.plink2, excl_file=excl_var_file, out=new_bfile)
        
        # Perform new PC
        pc_file = _pca(bfile=new_bfile, plink2=args.plink2, npc=args.npc_rm, var_file=var_file, out=args.out)

        current_bfile = new_bfile

        if max_cycles > 0:

             # Find outliers
             cur_outlier_ids = _find_outliers(pc_file=pc_file, nsd=args.nsd_rm)
        
             tot_outliers = tot_outliers + len(cur_outlier_ids)
        else:
             break


    _clone_plink_files(bfile=current_bfile, plink2=args.plink2, out=args.out)

    if not args.keep_tmp:
        print('==================\nRemove temporary files...\n')
        for prefix in tmp_files:
            [os.remove(f) for f in glob.glob('{}*'.format(prefix))]


    print('==================\nDONE.')
    print('Removed {} outliers'.format(tot_outliers))
    print('Final bim/bed/fam files: {}.bed, {}.bim, {}.fam'.format(args.out, args.out, args.out))

