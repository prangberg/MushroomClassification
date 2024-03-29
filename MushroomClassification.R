
# This dataset includes descriptions of hypothetical samples corresponding to 23 species of gilled mushrooms in the Agaricus and Lepiota Family Mushroom drawn from The Audubon Society Field Guide to North American Mushrooms (1981). 
#Each species is identified as definitely edible, definitely poisonous, or of unknown edibility and not recommended. This latter class was combined with the poisonous one. The Guide clearly states that there is no simple rule for determining the edibility of a mushroom; 
#no rule like "leaflets three, let it be'' for Poisonous Oak and Ivy.

#I downloaded the data from Kaggle
#https://www.kaggle.com/uciml/mushroom-classification
#and saved it as a .csv in the project's folder
library(tidyverse)
library(caret)
library(randomForest)
library(ggplot2)

#Ingest the CSV
mushrooms <- read.csv("mushrooms.csv", colClasses = "character") 
#check if there were any problems during the import - read.csv worked better for me than read_csv, since the later tried to convert 'bruises' and 'gill-attachment' to a logical variable, which cause problems.
problems(mushrooms)

dim(mushrooms)
#The dataset has 8124 entries with 23 columns. 

glimpse(mushrooms)

#The values are single letter. We can find the meaning in the definition on kaggle.com:
#The columns are already labeled, but the single letter abbreviations are not very meaningful.

#Definition of columns from kaggle
# classes: edible=e, poisonous=p
# cap-shape: bell=b,conical=c,convex=x,flat=f, knobbed=k,sunken=s
# cap-surface: fibrous=f,grooves=g,scaly=y,smooth=s
# cap-color: brown=n,buff=b,cinnamon=c,gray=g,green=r,pink=p,purple=u,red=e,white=w,yellow=y
# bruises: bruises=t,no=f
# odor: almond=a,anise=l,creosote=c,fishy=y,foul=f,musty=m,none=n,pungent=p,spicy=s
# gill-attachment: attached=a,descending=d,free=f,notched=n
# gill-spacing: close=c,crowded=w,distant=d
# gill-size: broad=b,narrow=n
# gill-color: black=k,brown=n,buff=b,chocolate=h,gray=g, green=r,orange=o,pink=p,purple=u,red=e,white=w,yellow=y
# stalk-shape: enlarging=e,tapering=t
# stalk-root: bulbous=b,club=c,cup=u,equal=e,rhizomorphs=z,rooted=r,missing=?
# stalk-surface-above-ring: fibrous=f,scaly=y,silky=k,smooth=s
# stalk-surface-below-ring: fibrous=f,scaly=y,silky=k,smooth=s
# stalk-color-above-ring: brown=n,buff=b,cinnamon=c,gray=g,orange=o,pink=p,red=e,white=w,yellow=y
# stalk-color-below-ring: brown=n,buff=b,cinnamon=c,gray=g,orange=o,pink=p,red=e,white=w,yellow=y
# veil-type: partial=p,universal=u
# veil-color: brown=n,orange=o,white=w,yellow=y
# ring-number: none=n,one=o,two=t
# ring-type: cobwebby=c,evanescent=e,flaring=f,large=l,none=n,pendant=p,sheathing=s,zone=z
# spore-print-color: black=k,brown=n,buff=b,chocolate=h,green=r,orange=o,purple=u,white=w,yellow=y
# population: abundant=a,clustered=c,numerous=n,scattered=s,several=v,solitary=y
# habitat: grasses=g,leaves=l,meadows=m,paths=p,urban=u,waste=w,woods=d

#data cleaning
#Labeling the Columns

# We'll create human-friendly names for each category.

#Map the data to a factor
mushrooms <- mushrooms %>% map_df(function(.x) as.factor(.x))

str(mushrooms)
#Notice that "veil.type" only has one single level, so this variable is fairly useless for any analysis and we can ignore it. In a larger dataset it would make sense to remove it in order to reduce complexity, but in this small dataset I omit this step.
#Every other variabel has 2-12 different levels.

#For each variable we define meaningful (and easy to understand) variable values, baszed on the definitions on Kaggle.
levels(mushrooms$class) <- c("edible", "poisonous")
levels(mushrooms$cap.shape) <- c("bell", "conical", "flat", "knobbed", "sunken", "convex")
levels(mushrooms$cap.color) <- c("buff", "cinnamon", "red", "gray", "brown", "pink", "green", "purple", "white", "yellow")
levels(mushrooms$cap.surface) <- c("fibrous", "grooves", "scaly", "smooth")
levels(mushrooms$bruises) <- c("no", "yes")
levels(mushrooms$odor) <- c("almond", "creosote", "foul", "anise", "musty", "none", "pungent", "spicy", "fishy")
levels(mushrooms$gill.attachment) <- c("attached", "free")
levels(mushrooms$gill.spacing) <- c("close", "crowded")
levels(mushrooms$gill.size) <- c("broad", "narrow")
levels(mushrooms$gill.color) <- c("buff", "red", "gray", "chocolate", "black", "brown", "orange", "pink", "green", "purple", "white", "yellow")
levels(mushrooms$stalk.shape) <- c("enlarging", "tapering")
levels(mushrooms$stalk.root) <- c("missing", "bulbous", "club", "equal", "rooted")
levels(mushrooms$stalk.surface.above.ring) <- c("fibrous", "silky", "smooth", "scaly")
levels(mushrooms$stalk.surface.below.ring) <- c("fibrous", "silky", "smooth", "scaly")
levels(mushrooms$stalk.color.above.ring) <- c("buff", "cinnamon", "red", "gray", "brown", "pink", "green", "purple", "white", "yellow")
levels(mushrooms$stalk.color.below.ring) <- c("buff", "cinnamon", "red", "gray", "brown", "pink", "green", "purple", "white", "yellow")
levels(mushrooms$veil.type) <- "partial"
levels(mushrooms$veil.color) <- c("brown", "orange", "white", "yellow")
levels(mushrooms$ring.number) <- c("none", "one", "two")
levels(mushrooms$ring.type) <- c("evanescent", "flaring", "large", "none", "pendant")
levels(mushrooms$spore.print.color) <- c("buff", "chocolate", "black", "brown", "orange", "green", "purple", "white", "yellow")
levels(mushrooms$population) <- c("abundant", "clustered", "numerous", "scattered", "several", "solitary")
levels(mushrooms$habitat) <- c("wood", "grasses", "leaves", "meadows", "paths", "urban", "waste")

str(mushrooms)
#data is looking good - ready to explore it

###data exploration and visualization

# We can now explore the data:
# The most important information for the person finding a mushroom is weather it is ebible or poisonous.
dim(mushrooms)
plyr::count(mushrooms$class)

#Almost half the mushrooms (48.2%) are poisonous

# We'll use ggplot2 to create some visualizations.

# Checking out the first two attributes: Cap Shape and CapSurface 
ggplot(mushrooms, aes(x = cap.shape, y = cap.surface, col = class)) + 
  scale_color_manual(breaks = c("edible", "poisonous"), 
                     values = c("green", "red")) +
  geom_jitter(alpha = 0.7) 
#We can see a couple of things in this plot:
#There is a very low (one-digit) number of mushrooms that have cap surfaces with grooves or conical cap shapes. All of those are poisonous
#Mushrooms with bell shaped caps are mostly edible. Those with flat or convex cap shapes are mostly poisonous.

# Checking out the next attributes: Cap Color and Odor (I skipped bruises).

ggplot(mushrooms, aes(x = cap.color, y = odor, col = class)) + 
  scale_color_manual(breaks = c("edible", "poisonous"), 
                     values = c("green", "red")) +
  geom_jitter(alpha = 0.7) 
  
  # you definitely want to avoid any odor that is fishy, spicy, pungent, musty, foul or creosote.
#Anise and almond seem to be very safe. Mushrooms with no odor are mostly safe, but some are poisonous.
  
# Checking out more attributes: Gill Color and Gill Size

ggplot(mushrooms, aes(x = gill.color, y = gill.size, col = class)) + 
  scale_color_manual(breaks = c("edible", "poisonous"), 
                     values = c("green", "red")) +
  geom_jitter(alpha = 0.7) 

#The Gill Colors red and orange are safe. Green is always poisonous.
#If the Gill size is groad the following colors are safe too: black,brown, orange, purple.

#Looking at the stark color above and below the rind.

ggplot(mushrooms, aes(x = stalk.color.above.ring , y = stalk.surface.above.ring, col = class)) + 
  scale_color_manual(breaks = c("edible", "poisonous"), 
                     values = c("green", "red")) +
  geom_jitter(alpha = 0.7) 

# We can see many combinations which are defintelly to avoid (buff/green, brow) and a few that are safe (smooth + red/gray/pink)

#Finally we take a look at population and spore print color.

ggplot(mushrooms, aes(x = spore.print.color , y = population, col = class)) + 
  scale_color_manual(breaks = c("edible", "poisonous"), 
                     values = c("green", "red")) +
  geom_jitter(alpha = 0.7) 

# Again, we see several combinations which are safe, incl. any mushrooms with a numerous population or buff, orange , purple, or yellow spore prints.

ggplot(mushrooms, aes(x = mushrooms$cap.color  , y = mushrooms$spore.print.color, col = class)) + 
  scale_color_manual(breaks = c("edible", "poisonous"), 
                     values = c("green", "red")) +
  geom_jitter(alpha = 0.7) + facet_wrap(mushrooms$odor)

# There are clearly pattern, so let's try to find a model to predict if a mushroom is edible or not.
#It looks like we might be able to make a good prediction using a regression model, but we already used that in the previous MovieLens exercise and want to use a 'real' machine learning model this time. 


###modeling approach

#Split the data into training and validation sets:

set.seed(1)
# Validation set will be 10% 
test_index <-
  createDataPartition(
    y = mushrooms$class,
    times = 1,
    p = 0.1,
    list = FALSE
  )
edx <- mushrooms[-test_index, ]
validation <- mushrooms[test_index, ]


### Random Forest 


set.seed(1)
model_rf <- randomForest(class ~ ., ntree = 30, data = edx)
plot(model_rf)

#The plot shows that above 15 trees, the error isn’t decreasing anymore and is very close to 0.

edx$predicted <- predict(model_rf ,edx)
confusionMatrix(data = edx$predicted, reference = edx$class , 
                positive = "edible")
# Using this model, there are no errors: This is a perfect prediction of which mushrooms are edible or poisonous.

var_imp <-importance(model_rf) %>% data.frame() %>% 
  rownames_to_column(var = "Variable") %>% 
  arrange(desc(MeanDecreaseGini))

var_imp

#Importance of factors
ggplot(var_imp, aes(x=reorder(Variable, MeanDecreaseGini), y=MeanDecreaseGini, fill=MeanDecreaseGini)) +
  geom_bar(stat = 'identity') +
  geom_point() +
  coord_flip() +
  xlab("Factors") +
  ggtitle("Importance of Factors")

#A higher descrease in Gini means that a particular predictor variable plays a greater role in partitioning the data into the defined classes.
#The plot indicates that Odor is the most predicive variable in determining edibility.

#We can confirm the importance of odor when looking at this plot:

ggplot(mushrooms, aes(x = odor, y = class, col = class)) + 
  scale_color_manual(breaks = c("edible", "poisonous"), 
                     values = c("green", "red"))+ geom_point(position='jitter') 
#Actually any mushroom that does have an odor (i.e. not 'none') can be predicted:
#Almond or Anise are always safe. Creosote, foul, pungent, spicy or fishy are always poisonous.
#Only those mushrooms without odor cannot be predicted, even though it seems that most are edible.

#Taking a quick look at the second most important factor, in combination with odor:
ggplot(mushrooms, aes(x = spore.print.color, y = odor, col = class)) + 
  scale_color_manual(breaks = c("edible", "poisonous"), 
                     values = c("green", "red")) +
  geom_jitter(alpha = 0.6) 
# This plot helps reduce the large uncertainty we had with odorless (odor=none) mushrooms. 
#We can eat any odorless mushroom exceopt those with green or white spore print color.
#We could continue this exercise and would probably come up with a very precise regression model, but let's focus on our Random Tree prediction.

#Let's apply the model to our validation set and see how well it makes predictions:
validation$predicted <- predict(model_rf ,validation)

confusionMatrix(data = validation$predicted, reference = validation$class , positive = "edible")

#This is a perfect prediction - Accuracy, Sensitivity and Specificity are 1.00.

