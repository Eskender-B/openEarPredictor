# openEarPredictor
predict.pl is a perl script that classifies a given TEST corpus or a single .arff file (file containing extracted features
of an audio file)
 
  Usage: perl predict.pl <corpus_path ¦ arff file (must end in .arff)>  [SMILExtract config for corpus mode]

steps to train, predict/evaluate a model:
1. Download and extract openEar from http://downloads.sourceforge.net/project/openart/openEAR-0.1.0.tar.gz
2. Copy predict.pl in scripts/modeltrain/
3. Copy emobase_live3.conf and emobase_live1.conf in config/

4. In order to train a model from a corpus of audio files arragne the corpus directory in the following format
  (class1 and class2 are used as labels)
  corpus/
  |  
    class1/                                     class2/                                               class3/  ...
    |                                           |                                                     |        
      -audio1_from_class1.wav                   -audio1_from_class2.wav
      -audio2_from_class2.wav                   -audio2_from class2.wav
      .                                         .
      .                                         .  
      .
5. Train a model
      cd scripts/modeltrain/
      perl buildmodel.pl /path/to/your/corpus/ emobase.conf
  
  or if you want different kinds of features extracted use emo_IS09.conf, emo_large.conf,
  MFCC12_E_D_A.conf, MFCC12_E_D_A_Z.conf in place of emobase.conf
  
6. To predict and evaluate the model arragne testdata in the same format as #5 and execute
      
      cd scripts/modeltrain/
      perl predict.pl /path/to/your/testcorpus/ emobase.conf  (or the corresponding config file used in training)
      
7. For live emotion recognition, cd back into top level directory and execute (need to install portaudio for this)

      ./SMILExtract -C config/emobase_live1.conf  (For the classifier using emobase.conf)
      ./SMILExtract -C config/emobase_live3.conf  (For the classifiers using emobase.conf emo_large.conf and emo_IS09.conf)
  
8. For more info see doc/openEAR_tutorial.pdf
