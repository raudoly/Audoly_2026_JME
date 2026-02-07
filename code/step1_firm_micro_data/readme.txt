Replication instructions: firm_micro

This folder contains two subfolders. Run BDS first because ARD/ABS depends on outputs created there.

1) BDS (must run first)
   Location: code/data/firm_micro/bds

   a) Edit bds/globals.do:
      - Set global project to your project folder
      - Set global raw to the location of the raw BSD data

   b) Run in order:
      1. bds/extract.do
         -> creates yearly firm/establishment files in ${work}/data
      2. bds/build.do
         -> builds ${work}/data/firmspan (used by ARD/ABS)
      3. bds/moments.do
         -> writes moments to ${tables}/bsd_moments.xlsx

2) ARD/ABS (after BDS)
   Location: code/data/firm_micro/ard_abs

   a) Edit ard_abs/globals.do:
      - Set global project to your project folder

   b) Run in order:
      1. ard_abs/build.do 
         -> builds ${work}/data/abs_ard_sample from BSD + ARD/ABS raw inputs.
      2. ard_abs/moments.do
         -> writes moments to ${tables}/ard_abs_moments.xlsx
      3. ard_abs/op_decomposition.do
         -> writes OP decomposition to ${tables}/ard_abs_decomposition.xlsx

Notes
- Outputs are written under ${work}/tables.
- ARD/ABS uses ${work}/data/firmspan created by the BDS build step.