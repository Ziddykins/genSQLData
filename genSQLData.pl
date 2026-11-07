#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Getopt::Long;
my @columns;
my ($count, $table, $pgsql, $file_firstnames, $file_lastnames, $ipsum);

GetOptions(
    'columns|c=s{1,}' => \@columns,
    'count|r=i'       => \$count,
    'table|t=s'       => \$table,
    'first|f=s'       => \$file_firstnames,
    'last|l=s'        => \$file_lastnames,
    'ipsum|i=s'       => \$ipsum,
    'pgsql|p'         => \$pgsql,
    'help|?+'         => sub { help() },
);

my (@first_names, @last_names, @lorem_ipsum);
$file_firstnames //= 'first.txt';
$file_lastnames  //= 'last.txt';
$ipsum //= 'ipsum.txt';
$count //= 25;

if (!$table) {
    help();
    die "Need to supply --table\n";
}

if (!scalar @columns) {
    help();
    die "Need to supply at least one --column\n";
}

load_data();

my @data    = split /;/, shift;
my $data_count   = scalar @data;
my $column_count = scalar @columns;

if ($data_count != $column_count) {
    die "Column count ($column_count) doesn't match the received indicator count ($data_count)\n";
}

for my $i (0 .. $count - 1) {
    print "Column $columns[$i] will use data type $data[$i]\n";
}

for (1 .. $count) {
    my @values;
    my $out_data = !$pgsql ? "INSERT INTO `$table` (`" . join("\Q`, `", @columns) . "\E`) VALUES ("
                           : "INSERT INTO $table (" . join(", \Q", @columns) . "\E) VALUES (";

    for (my $i=0; $i<scalar @data; $i++) {
        my ($type, $args) = split /:/, $data[$i];

        if ($type eq 'V') {
            my $string;
            $args //= 25;
            for (1 .. $args) {
                chomp (my $word = $lorem_ipsum[int(rand(scalar @lorem_ipsum)-1)]);
                $string .= $word . ' ';
            }
            push(@values, "'$string'");
        } elsif ($type =~ /^[FL]{1}$/) {
            my $name = $type eq 'F'
                ? $first_names[int(rand(scalar @first_names)-1)]
                : $last_names[int(rand(scalar @last_names)-1)];
            chomp $name;
            push(@values, "'$name'");
        } elsif ($type eq 'B') {
            my $pick = int(rand(2)) ? 'True' : 'False';
            push(@values, "'$pick'");
        } elsif ($type eq 'D') {
            if ($args && $args eq 'T') {
                $out_data .= "NOW()";
            } else {
                my ($year, $month, $day, $hour, $min, $sec) =
                    (int(rand(14)+2024),int(rand(12)+1),int(rand(28)+1),int(rand(23)+1),int(rand(59)+1),int(rand(59)+1));
                my $date = sprintf("%d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec);
                push(@values, "'$date'");
            }
        } elsif ($type eq 'N') {
            push(@values, "NULL");
        } elsif ($type eq 'I') {
            $args //= 5000;
            my $num = int(rand($args));
            push(@values, "$num");
        } elsif ($type eq 'P') {
            my ($area, $district, $ending) = (int(rand(999)), int(rand(999)), int(rand(9999)));
            my $number = sprintf("%03d-%03d-%04d", $area, $district, $ending);
            push(@values, "'$number'");
        } elsif ($type =~ /IP/) {
            our ($o1, $o2, $o3, $o4);
            $o1 = int(rand(255)+1);
            no strict 'refs';
            for (2 .. 4) {
                ${"o$_"} = int(rand(255));
            }
            use strict 'refs';
            my $ip = "$o1.$o2.$o3.$o4";
            push(@values, "'$ip'");
        } elsif ($type eq 'E') {
            chomp(my $sender = $first_names[int(rand(scalar @first_names)-1)]);
            chomp($sender   .= $last_names[int(rand(scalar @last_names)-1)]);
            chomp(my $domain = $lorem_ipsum[int(rand(scalar @lorem_ipsum)-1)]);
            my $email = "'$sender\@${domain}.com'";

            push(@values, $email);
        } elsif ($type eq 'M') {
            my $amount = sprintf("%d.%02d", int(rand(1000)+1), int(rand(99)+1));
            push(@values, "'$amount'");
        } elsif ($type eq 'CC') {
            my $cc = ($args eq 'MC' ? 2720 : $args eq 'V' ? 4724 : $args eq 'DI' ? 6011 : 1234);
            for (1 .. 3) {
                $cc .= sprintf(" %04d", int(rand(9999)+1));
            }
            push(@values, "'$cc'");
        } elsif ($type eq 'PW') {
            my $password;
            $args //= 10;

            for (1 .. $args) {
                $password .= chr(int(rand(25)+65));
            }
            push(@values, "'$password'");
        } elsif ($type eq 'LF') {
            my $word = $lorem_ipsum[int(rand(scalar @lorem_ipsum))];
            $args //= 'txt';
            my $filename = "$word.$args";
            push(@values, "'$filename'");
        } elsif ($type eq 'A') {
            my @choices = split /,/, $args;
            my $pick = $choices[int(rand(scalar @choices))];
            push(@values, "'$pick'");
        } elsif ($type eq 'UU') {
            my $uuid = sprintf(
                "%s-%04d-%04d-%04d-%s", 
                gen_random_str(8),
                int rand 9999,
                int rand 9999,
                int rand 9999,
                gen_random_str(12)
            );
            push(@values, "'$uuid'");
        } else {
            die "Invalid data in data string: '$type'\n";
        }

    }

    $out_data .= join(', ', @values);
    $out_data .= ");\n\n";
    print $out_data;
}

sub gen_random_str {
    my $length = $_[0];
    my $out;

    for (1 .. $length) {
        my $pick = int rand 2;
        my $start = 48;
        my $end = 58;

        if ($pick) {
            $start = 97;
            $end = 102;
        }

        $out .= chr(int(rand($end - $start) + $start));
    }
    return $out;
}

sub load_data {
    open my $fh_fn, '<', $file_firstnames;
        @first_names = <$fh_fn>;
    close $fh_fn;

    open my $fh_ln, '<', $file_lastnames;
        @last_names = <$fh_ln>;
    close $fh_ln;

    open my $fh_li, '<', $ipsum;
        @lorem_ipsum = split / /, <$fh_li>;
    close $fh_li;

    s/[\r\n]+/\n/g for @first_names;
    s/[\r\n]+/\n/g for @last_names;
    s/[\r\n]+/\n/g for @lorem_ipsum;

    print scalar @first_names . " first names loaded\n";
    print scalar @last_names  . " last names loaded\n";
    print scalar @lorem_ipsum . " lorem ipsum words loaded\n";
}

sub help {
    print <<HELP;
- MySQL Example Data Generator -
Usage:
    ./$0 --table <table> --columns <column1 column2> --count <#rows> "<identifiers>"
    Note: Columns can't be the last flag before the identifiers, and on windows, you
          must use double quotes instead of single quotes.

    Identifiers:
        I[:#]        - Integer - Number between 1 and 5000
        B            - Boolean - 'True' or 'False'
        M            - Currency in the format of #.##
        D[:T]        - Date - 'YYYY-MM-DD hh:mm:ss' format - if T is supplied as an argument,
                       NOW() is supplied
        F            - First name, picks a random one
        L            - Last name, picks a random one
        N            - NULL
        P            - Phone number - xxx-xxx-xxxx
        E            - Email - Random first and last name for sender and lorem word for domain
        IP           - IP address - May be private
        A:a,b,c      - Randomly picks one of the supplied options
        CC[:MC|V|DI] - Generates a probably-invalid credit card, follows the first digits
                       of actual cards if arg is specified
        V[:#]        - A randomly generated sentence of # words long, good for descriptions
        PW[:#]       - Randomly generated password of # length
        LF[:ext]     - Local file name, takes random word from lorem and appends .txt,
                       or supplied extension
        UU           - Random UUID-shaped string (not necessarily a valid UUID)

    Examples:
        ./$0 --table tbl_mail --columns id account_id to from subject message date read important --count 25 'I;I;E;E;V:5;V:25;D;B;B'
HELP
}
