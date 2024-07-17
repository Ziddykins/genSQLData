#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Getopt::Long;

my ($count, $table);
my ($file_firstnames, $file_lastnames, $ipsum);
my (@first_names, @last_names, @lorem_ipsum);

my @columns;

GetOptions(
  'columns|c=s{1,}' => \@columns,
  'count|r=i'       => \$count,
  'table|t=s'       => \$table,
  'first|f=s'       => \$file_firstnames,
  'last|l=s'        => \$file_lastnames,
  'ipsum|i=s'       => \$ipsum,
  'help|?+'         => sub { help() },
);

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
my $out_data;

for (1 .. $count) {
    $out_data = "INSERT INTO `$table` (`" . join('`, `', @columns) . "`) VALUES (";

    my $data_count   = scalar @data;
    my $column_count = scalar @columns;

    if ($data_count != $column_count) {
        die "Column count ($column_count) doesn't match the received indicator count ($data_count)\n";
    }

    for (my $i=0; $i<scalar @data; $i++) {
        my ($type, $args) = split /:/, $data[$i];

        if ($type eq 'V') {
            my $string;
            $args //= 25;
            for (1 .. $args) {
                chomp (my $word = $lorem_ipsum[int(rand(scalar @lorem_ipsum)-1)]);
                $string .= $word . ' ';
            }
            $out_data .= "'$string'";
        } elsif ($type =~ /^[FL]{1}$/) {
            my $name = $type eq 'F'
                ? $first_names[int(rand(scalar @first_names)-1)]
                : $last_names[int(rand(scalar @last_names)-1)];
            chomp $name;
            $out_data .= "'$name'";
        } elsif ($type eq 'B') {
            my $pick = int(rand(2)) ? 'True' : 'False';
            $out_data .= "'$pick'";
        } elsif ($type eq 'D') {
            if ($args && $args eq 'T') {
                $out_data .= "NOW()";
            } else {
                my ($year, $month, $day, $hour, $min, $sec) =
                    (int(rand(14)+2024),int(rand(12)+1),int(rand(28)+1),int(rand(23)+1),int(rand(59)+1),int(rand(59)+1));
                my $date = sprintf("%d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec);
                $out_data .= "'$date'";
            }
        } elsif ($type eq 'N') {
            $out_data .= "NULL";
        } elsif ($type eq 'I') {
            my $args //= 5000;
            my $num = int(rand($args));
            $out_data .= "$num";
        } elsif ($type eq 'P') {
            my ($area, $district, $ending) = (int(rand(999)), int(rand(999)), int(rand(9999)));
            my $number = sprintf("%03d-%03d-%04d", $area, $district, $ending);
            $out_data .= "'$number'";
        } elsif ($type =~ /IP/) {
            our ($o1, $o2, $o3, $o4);
            $o1 = int(rand(255)+1);
            no strict 'refs';
            for (2 .. 4) {
                ${"o$_"} = int(rand(255));
            }
            use strict 'refs';
            my $ip = "$o1.$o2.$o3.$o4";
            $out_data .= "'$ip'";
        } elsif ($type eq 'E') {
            chomp(my $sender = $first_names[int(rand(scalar @first_names)-1)]);
            chomp($sender    = $last_names[int(rand(scalar @last_names)-1)]);
            chomp(my $domain = $lorem_ipsum[int(rand(scalar @lorem_ipsum)-1)]);
            my $email = "$sender\@$domain.com";

            $out_data .= "'$email'";
        } elsif ($type eq 'M') {
            my $amount = sprintf("%d.%02d", int(rand(1000)+1), int(rand(99)+1));
            $out_data .= "'$amount'";
        } elsif ($type eq 'CC') {
            my $cc = ($args eq 'MC' ? 2720 : $args eq 'V' ? 4724 : $args eq 'DI' ? 6011 : 1234);
            for (1 .. 3) {
                $cc .= sprintf(" %04d", int(rand(9999)+1));
            }
            $out_data .= "'$cc'";
        } elsif ($type eq 'PW') {
            my $password;
            $args //= 10;

            for (1 .. $args) {
                $password .= chr(int(rand(25)+65));
            }
            $out_data .= "'$password'";
        } elsif ($type eq 'LF') {
            my $word = $lorem_ipsum[int(rand(scalar @lorem_ipsum))];
            $args //= 'txt';
            my $filename = "$word.$args";
            $out_data .= "'$filename'";
        } else {
            die "Invalid data in data string: '$type'\n";
        }
        $out_data .= ', ';
    }
    $out_data =~ s/, $//;
    print $out_data . ");\n\n";
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

    print scalar @first_names . " first names loaded\n";
    print scalar @last_names  . " last names loaded\n";
    print scalar @lorem_ipsum . " lorem ipsum words loaded\n";
}

sub help {
    print <<HELP;
- MySQL Example Data Generator -
Usage:
    ./$0 --table <table> --count <#rows> --columns <column1 column2> <identifiers>

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
        E            - Email - Random first name for sender and random word from lorem for domain
        IP           - IP address - May be private
        CC[:MC|V|DI] - Generates a probably-invalid credit card, follows the first digits
                       of actual cards if arg is specified
        V[:#]        - A randomly generated sentence of # words long, good for descriptions
        PW[:#]       - Randomly generated password of # length
        LF[:ext]     - Local file name, takes random word from lorem and appends .txt,
                       or supplied extension

    Examples:
        ./$0 --table tbl_mail --columns id account_id to from subject message date read important --count 25 'I;I;E;E;V:5;V:25;D;B;B'
HELP
}
