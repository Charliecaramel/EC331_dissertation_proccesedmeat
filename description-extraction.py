#!/usr/bin/env python
# coding: utf-8

# In[1]:


# Import library (Must run)

import re
import numpy as np


# In[1]:


#Read all descriptions (Must run)

rawPath = "C:\\Users\\cmlvh\\OneDrive\\桌面\\Python_Charlotte\\raw\\"
descFile = open(rawPath + "unique_upc_without_frozen.txt", 'r')
descLines = descFile.readlines()

print("Length of file: ", len(descLines))


# In[9]:


# Splits every word in the descriptions given (Must run)

AllText = ""

for i in descLines:
    # i[0:-1] excludes new lines "\n", replace \n with a space
    AllText = AllText + i[0:-1] + " "

regexStr = ' |/|\-|%' 

splitDesc = re.split(regexStr, AllText)

print("Number of words: ", len(splitDesc))


# In[10]:


# Finds all the unique words in the descriptions (Must run)

uniqueWordList = [""]

isUnique = True

for i in splitDesc:
    isUnique = True
    for j in uniqueWordList:
        if (i == j):
            isUnique = False
            break
    if isUnique:
        uniqueWordList.append(i)

print("Number of unique words: ", len(uniqueWordList))


# In[5]:


# Run this to see the number of descriptions with each unique word (optional)

wordDict = {}

for i in uniqueWordList:
    wordDict[i] = 0
    for j in splitDesc:
        if (i == j):
            wordDict[i]+=1
            
result = dict(sorted(wordDict.items(), key=lambda item: item[1]))

for i in result:
    print(i, result[i])


# In[102]:


# Run this to see all unique words (optional)
for i in uniqueWordList:
    print(i)


# In[11]:


# (Must run)

def outputWords(includeWords, descLines, regexStr, outputIncludedOrExcluded):
    
    containsInputWords = np.zeros(len(descLines))

    for i in range(0, len(descLines)):
        
        Words_i = re.split(regexStr, descLines[i][0:-1])

        for j in Words_i:
            for k in includeWords:
                if(j == k):
                    containsInputWords[i]=1
                    break
            if(containsInputWords[i]==1):
                break
    
    
    for i in range(0, len(containsInputWords)):
        if containsInputWords[i] == outputIncludedOrExcluded:
            print("upc_descr == " + "\""+ descLines[i][0:-1]+ "\"" + "|", end=" ")
    
    


# In[35]:


# (Must run)

def outputWords2(includeWords, descLines, regexStr, outputIncludedOrExcluded):
    
    containsInputWords = np.zeros(len(descLines))

    for i in range(0, len(descLines)):
        
        Words_i = re.split(regexStr, descLines[i][0:-1])

        for j in Words_i:
            for k in includeWords:
                if(j == k):
                    containsInputWords[i]=1
                    break
            if(containsInputWords[i]==1):
                break
    
    
    for i in range(0, len(containsInputWords)):
        if containsInputWords[i] == outputIncludedOrExcluded:
            print( descLines[i][0:-1])
    


# In[36]:


# Run this to see all descriptions which are excluded or included from the input word list (Must run)

# If outputIncludedOrExcluded = 1, prints all included words
# If outputIncludedOrExcluded = 0, prints all excluded words

outputIncludedOrExcluded = 1

# If you want to give a file for the input words make isInputFile = 1
# If you want to give a list of words yourself, make  isInputFile = 0

isInputFile = 0

# Name of input word file
inputPath = "C:\\Users\\cmlvh\\OneDrive\桌面\\Python_Charlotte\\inputs\\"
inputWordsFileName = "food-words.txt"

# List of included words
includeWords = ["CH"]

if(isInputFile == 1):
    
    includeWordsFile = open(inputPath + inputWordsFileName, 'r')
    includeWords = includeWordsFile.readlines()
    for i in range(0, len(includeWords)):
        includeWords[i] = includeWords[i][0:-1]



outputWords2(includeWords, descLines, regexStr, outputIncludedOrExcluded)


# In[ ]:




