package HarbourX::NotJenkins::Utils;

use common::sense;

use Archive::Extract;
use Archive::Tar;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Data::Dump qw(dump);
use File::Find;
use File::Path;
use File::Slurp;
use File::Temp;
use HTTP::Request;
use LWP;





sub download_repo {
    my ($repo_name) = @_;

    my $project_sth = database->prepare(q{
        SELECT id, repo_name, repo_owner, repo_user, repo_password
        FROM projects
        WHERE repo_name = ?
        AND enabled = 1
        LIMIT 1
    });

    $project_sth->execute($repo_name);

    my $repo = $project_sth->fetchall_arrayref({});

    die dump $repo;


    # my $options = setting("deployment_options");
    # 
    # # We want to get the file size first, so we issue a HEAD request followed by the actual download
    # my $download = HTTP::Request->new(
    #     GET => "https://github.com/UK2group/".$options->{repo_name}."/zipball/$branch"
    # );
    # 
    # $download->authorization_basic($options->{username}, $options->{password});
    # 
    # my $ua = LWP::UserAgent->new();
    # 
    # my $zipfile = File::Temp->new( SUFFIX => '.zip', UNLINK=> 0 );
    # my $response = $ua->request($download, $zipfile->filename);
    # 
    # if ($response->is_success) {
    #     # Actually the full path to the zipfile, not just the filename
    #     return $zipfile->filename;
    # } elsif ($response->is_error) {
    #     die 'Could not download zipball: ' . $response->code . ' ' . $response->message;
    # }
}


1;
