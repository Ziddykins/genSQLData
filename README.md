# genSQLData
Generates data for SQL tables using a string of identifiers

## Usage
```
chmod +x genSQLData.pl
./genSQLData.pl --table <table_name> --columns <space-separated list of column names> --count <# of rows> '<identifiers'
```
 48     Identifiers:
 49     |   I    - Integer - Number between 1 and 5000
 50     |   B    - Boolean - 'True' or 'False'
 51     |   D    - Date - 'YYYY-MM-DD hh:mm:ss' format
 52     |   F    - First name, picks a random one
 53     |   L    - Last name, picks a random one
 54     |   N    - NULL
 55     |   P    - Phone number - xxx-xxx-xxxx
 56     |   E    - Random first name and random word from lorem for domain
 57     |   IP   - IP address - May be private
 58     |   CC:# - Credit card - randomly generated CC, probably not valid
 59     |   V:#  - A randomly generated sentence of # words long
## Identifiers
| Identifier | Description | Arguments  |
|------------|-------------|------------|
| I | | |
| B | | |
| D | | |
| F | | |
| L | | |
| N | | |
| P | | |
| E | | |
| IP | | |
| CC | | |
| V | | |
