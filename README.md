# genSQLData
Generates data for SQL tables using a string of identifiers

## Usage
```
chmod +x genSQLData.pl
./genSQLData.pl --table <table_name> --columns <space-separated list of column names> --count <# of rows> '<identifiers'
```

## Identifiers
| Identifier | Arguments |  Description |
|   :---:    |    :---:  |--------------|
| I  | # | Integer - Number between 1 and 5000, or 1 and the argument specified |
| B  | None | Boolean - 'True' or 'False' |
| D  | T | Date - 'YYYY-MM-DD hh:mm:ss' format - if 'T' is supplied as an argument, NOW() is supplied |
| F  | None | First name, picks a random one from hard-coded list |
| L  | None | Last name, picks a random one from hard-coded list  |
| N  | None | NULL |
| P  | None | Phone number in the format of xxx-xxx-xxxx |
| E  | None | Email - Picks a random first name and a random word from the lorem ipsum for the domain |
| V  |  #   |  Varchar of <arg> length, pulls words from lorem ipsum |
| IP | None | Random IP address, could very well be a local IP address |
| PW | # | Generates a random uppercase password of <arg> length, or length of 10 if omitted |
| CC | DI, MC, V | Generates a probably-invalid credit card, follows the first digits of actual cards if arg is specified |

## Arguments
Arguments are supplied by appending them after a colon, on an identifier:
```
V:25  = varchar string of 25 words
D:T   = date, using NOW()
CC:MC = credit card with Mastercard IIN ranges
```
