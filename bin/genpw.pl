#!/usr/bin/perl
# vim: tabstop=2 expandtab shiftwidth=2 softtabstop=2

my $length = 16;
if (@ARGV) {
  $length = $ARGV[0];
}

print generatePassword($length) . "\n";
exit;


sub generatePassword {
  my $password;
  my $length = shift;
  my $nice = 'abcdefghijkmnpqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ';
  my $nums = '23456789';
  my $possible = $nice . '!@#%&<>/-=+';
  #Double the chances of getting "nice" characters
  $possible = $possible . $nums . $nice ;
  $previous = ' ';
  $newletter = ' ';
  while (length($password) < $length) {
    until ($newletter ne $previous) {
      $newletter = substr($possible, (int(rand(length($possible)))), 1);
    }
    $password .= $newletter;
    $previous = $newletter;
  }
  return $password;
} 
