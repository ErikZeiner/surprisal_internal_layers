SOURCE="results_orig"

Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/NS" -d NS_MAZE -o
Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/NS" -d NS -o
Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/DC" -d DC -o
Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/UCL" -d UCL -o
Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/Fillers" -d Fillers -o
Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/S_N400" -d S_N400 -o
Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/M_N400" -d M_N400 -o

#Rscript src/EZ_bf_modelling.R -i "$SOURCE/tuned-lens/NS" -d NS_MAZE -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/tuned-lens/NS" -d NS -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/tuned-lens/DC" -d DC -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/tuned-lens/UCL" -d UCL -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/tuned-lens/Fillers" -d Fillers -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/tuned-lens/S_N400" -d S_N400 -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/tuned-lens/M_N400" -d M_N400 -o
#
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/du" -d MECO/du -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/ee" -d MECO/ee -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/en" -d MECO/en -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/fi" -d MECO/fi -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/ge" -d MECO/ge -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/gr" -d MECO/gr -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/he" -d MECO/he -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/it" -d MECO/it -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/ko" -d MECO/ko -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/no" -d MECO/no -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/ru" -d MECO/ru -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/sp" -d MECO/sp -o
#Rscript src/EZ_bf_modelling.R -i "$SOURCE/logit-lens/MECO/tr" -d MECO/tr -o