A special thanks to Claude Code for helping me build this script!

##Setup

#1. 

Retrieve one or more AG API keys. These API keys must be your own. They are free with a Google account.

#2. 

Install dependencies, usually done through
```bash
pip install -r requirements.txt
```

#3.

Create a file named ".env" within the same folder as "api_based_ism.py".
Type in your API keys like this, one per line:
```
AG_API_KEY_1="your_key_goes_here"
```
If you have more than one key, add them the same way, and the script will automatically use all of them in parallel -- no code changes needed.
```
AG_API_KEY_1="your_first_key"
AG_API_KEY_2="your_second_key"
AG_API_KEY_3="your_third_key"
```

#4.

Configure the file for your run. Gene strand, name, and chromosome, as well as the ISM region scores are predicted for and the model context window, can be modified at the top.
If you would like to add scorers/modalities, include them under _build_scorers(), and you will need to update extract_score() accordingly to filter for a specific, single value.


##Benchmarks

#Note: All of these benchmarks were retrieved when using five scorers across the three splicing modalities (what is currently in the api_based_ism.py file).

For a 5kb region in the center of BAG3, here were the results: 
1 key: 12.98 min
2 keys: 6.77 min
3 keys: 5.66 min
4 keys: 4.38 min
5 keys: 3.26 min

Extrapolating to a 48kb region (centered on BAG3 + 10kb up and downstream):
1 key: 2hr 5 min
2 keys: 1hr 5 min
3 keys: 55 min
4 keys: 42 min
5 keys: 31 min

File sizes:
For a 5kb region run, the .csv files returned were consistently 1.5MB. Extrapolating to a 48kb region, this would be 14.65MB
