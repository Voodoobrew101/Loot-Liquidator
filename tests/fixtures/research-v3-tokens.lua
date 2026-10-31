-- Research v3 token fixture (tests only): one unreviewed list for a token that also has a
-- reviewed record (the reviewed one must win), and one for a new token.
return {schemaVersion=1,processing={
},tokenRewards={
{recordID='v3token:900001',tokenID=900001,kind='open',gameMode='Retail',evidenceStatus='RESEARCH_RELATIONSHIP',
 independentReview='NOT_REVIEWED',listComplete=true,requirements={},requirementsReviewed=false,confidence0to100=60,
 patchStartBuild=1,patchEndBuild=2147483647,sourceRevision='fixture',sourceURLs={'https://example.test/v3'},rewards={900010}},
{recordID='v3token:900007',tokenID=900007,kind='open',gameMode='Retail',evidenceStatus='RESEARCH_RELATIONSHIP',
 independentReview='NOT_REVIEWED',listComplete=false,requirements={},requirementsReviewed=false,confidence0to100=40,
 patchStartBuild=1,patchEndBuild=2147483647,sourceRevision='fixture',sourceURLs={'https://example.test/v3b'},rewards={900012,900013}},
}}
