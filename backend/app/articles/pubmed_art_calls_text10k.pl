use LWP::Simple;
use lib '/Users/rishikabansal/perl5/lib/perl5';  # Add your local lib path
use Mozilla::CA;  # Now Perl should find this
use JSON;
use URI::Escape;
use Encode qw(encode_utf8);

# Download PubMed records that are indexed in MeSH for contraception 
# and were also published between 2020 and 2025.

my $db = 'pubmed';
my $raw_query = 'contraception AND 2020:2027[pdat]';
my $query = uri_escape($raw_query);
my $api = 'f3765daf5a24c425e4b65dccf0555c5c7508';

#assemble the esearch URL
my $base = 'https://eutils.ncbi.nlm.nih.gov/entrez/eutils/';
my $url = $base . "esearch.fcgi?db=$db&term=$query&usehistory=y&retmax=10000&api_key=$api";

#post the esearch URL
my $output = get($url);

#parse WebEnv and QueryKey
my $web = $1 if ($output =~ /<WebEnv>(\S+)<\/WebEnv>/);
my $key = $1 if ($output =~ /<QueryKey>(\d+)<\/QueryKey>/);
my $count = $1 if ($output =~ /<Count>(\d+)<\/Count>/);

print "Found $count records matching your search criteria.\n";

### include this code for ESearch-EFetch
#open output file
open(my $fh, '>', 'pubmed_contraception_abstracts.json') or die "Cannot open file: $!";
binmode($fh, ":encoding(UTF-8)");

#retrieve data in 10k blocks
# Create JSON array to store all abstracts
my @all_abstracts = ();
	
my $efetch_url = $base . "efetch.fcgi?db=$db&query_key=$key&WebEnv=$web";
$efetch_url .= "&rettype=abstract&retmode=text&retmax=10000&api_key=$api";

my $data = get($efetch_url);
my @abstracts;
{
        use bytes;
        @abstracts = split /\n{3,}/, $data;
}
@abstracts = map { s/^\s+|\s+$//gr } @abstracts;

push @all_abstracts, @abstracts;

#convert to json
my $json = JSON->new->utf8->allow_nonref->canonical;
print {$fh} $json->encode(\@all_abstracts);
close $fh;

print "Data successfully exported to pubmed_contraception_abstracts.json\n";
print "Retrieved ", scalar(@all_abstracts), " abstracts.\n";