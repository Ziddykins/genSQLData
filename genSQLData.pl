#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Getopt::Long;

my ($count, $table);
my @columns;

GetOptions(
  'columns|c=s{1,}' => \@columns,
  'count|r=i'       => \$count,
  'table|t=s'       => \$table,
  'help|?+'         => sub { help() },
);

if (scalar @ARGV < 1) {
    help();
    die;
}

sub help {
    print <<EOF;
- MySQL Example Data Generator -
Usage:
    ./$0 --table <table> --count <#rows> --columns <column1 column2> <identifiers>

    Identifiers:
        I    - Integer - Number between 1 and 5000
        B    - Boolean - 'True' or 'False'
        D    - Date - 'YYYY-MM-DD hh:mm:ss' format
        F    - First name, picks a random one
        L    - Last name, picks a random one
        N    - NULL
        P    - Phone number - xxx-xxx-xxxx
        E    - Random first name and random word from lorem for domain
        C    - Currency - format of #.##
        IP   - IP address - May be private
        PW   - Random upper-cased password of length 10
        CC:* - Credit card - randomly generated CC, probably not valid
                 - Args: MC for mastercard, V for Visa, DI for Discover
        V:*  - A randomly generated sentence of # words long
                 - Args: <number> for number of words

    Examples:
        ./$0 --table tbl_mail --columns id account_id to from subject message date read important --count 25 'I;I;E;E;V:5;V:25;D;B;B'
EOF
}

my @names = qw/James Mary Robert Patricia John Jennifer Michael Linda David Elizabeth William Barbara Richard Susan Joseph Jessica Thomas Sarah Christopher Karen Charles Lisa Daniel Nancy Matthew Betty Anthony Sandra Mark Margaret Donald Ashley Steven Kimberly Andrew Emily Paul Donna Joshua Michelle Kenneth Carol Kevin Amanda Brian Melissa George Deborah Timothy Stephanie Ronald Dorothy Jason Rebecca Edward Sharon Jeffrey Laura Ryan Cynthia Jacob Amy Gary Kathleen Nicholas Angela Eric Shirley Jonathan Brenda Stephen Emma Larry Anna Justin Pamela Scott Nicole Brandon Samantha Benjamin Katherine Samuel Christine Gregory Helen Alexander Debra Patrick Rachel/;

my @lorem = qw/Lorem ipsum dolor sit amet consectetur adipiscing elit Sed eget nibh velit Vivamus luctus molestie lorem ac rhoncus Donec sem leo molestie ac nisl vel blandit tempus est Proin lacinia volutpat metus nec interdum Aenean lacus odio blandit id nisi sit amet venenatis commodo ex Nam convallis tellus vel imperdiet hendrerit mauris tortor pellentesque nisi at molestie massa ante a erat In nec iaculis arcu Nullam ac auctor urna Cras id nisl varius pulvinar ante quis lacinia erat Mauris elementum lectus interdum convallis efficitur ante leo convallis diam a interdum est dui nec dui Proin mattis diam in metus venenatis at porta leo facilisis/;

my @data    = split /;/, shift;
my $out_data;

for (1 .. $count) {
    $out_data = "INSERT INTO `$table` (`" . join('`, `', @columns) . "`) VALUES (";

    for (my $i=0; $i<scalar @data - 1; $i++) {
        my ($type, $args) = split /:/, $data[$i];
        $args //= 1;

        if ($type eq 'V') {
            my $string;
            for (1 .. $args) {
                $string .= $lorem[int(rand(scalar @lorem)-1)] . ' ';
            }
            $out_data .= "'$string'";
        } elsif ($type =~ /[FL]/) {
            my $name = $names[int(rand(scalar @names)-1)];
            $out_data .= "'$name'";
        } elsif ($type eq 'B') {
            my $pick = int(rand(2)) ? 'True' : 'False';
            $out_data .= "'$pick'";
        } elsif ($type eq 'D') {
            if ($args eq 'T') {
                $out_data .= "NOW()";
            } else {
                my ($year, $month, $day, $hour, $min, $sec) = (int(rand(14)+2024),int(rand(12)+1),int(rand(28)+1),int(rand(23)+1),int(rand(59)+1),int(rand(59)+1));
                my $date = sprintf("%d-%02d-%02d %02d:%02d:%02d", $year, $month, $day, $hour, $min, $sec);
                $out_data .= "'$date'";
            }
        } elsif ($type eq 'N') {
            $out_data .= "NULL";
        } elsif ($type eq 'I') {
            my $num = int(rand(5000));
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
            my $sender = $names[int(rand(scalar @names)-1)];
            my $domain = $lorem[int(rand(scalar @lorem)-1)];
            my $email  = "$sender\@$domain.com";

            $out_data .= "'$email'";
        } elsif ($type eq 'M') {
            my $amount = sprintf("%d.%02d", int(rand(1000)+1), int(rand(99)+1));
            $out_data .= "'$amount'";
        } elsif ($type eq 'C') {
            my $cc = ($args eq 'MC' ? 2720 : $args eq 'V' ? 4724 : $args eq 'DI' ? 6011 : 1234);
            for (1 .. 3) {
                $cc .= sprintf(" %04d", int(rand(9999)+1));
            }
            $out_data .= "'$cc'";
        } elsif ($type eq 'PW') {
            my $password;
            for (1 .. 15) {
                $password .= chr(int(rand(25)+65));
            }
            $out_data .= "'$password'";
        } else {
            die "Invalid data in data string: '$type'\n";
        }
        $out_data .= ', ';
    }
    $out_data =~ s/, $//;
    print $out_data . ");\n\n";
}
