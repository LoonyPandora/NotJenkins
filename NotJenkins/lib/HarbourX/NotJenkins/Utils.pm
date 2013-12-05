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





sub download_branch {
    my ($repo_name) = @_;

    my $project_sth = database->prepare(q{
        SELECT projects.id, repo_name, repo_owner, repo_user, repo_password, branch_name
        FROM projects
        LEFT JOIN branches ON projects.id = branches.project_id
        WHERE repo_name = ?
        AND enabled = 1
        LIMIT 1
    });

    $project_sth->execute($repo_name);

    my $repo = $project_sth->fetchall_hashref([]);

    my $download = HTTP::Request->new(
        GET => "https://github.com/".$repo->{repo_owner}."/".$repo->{repo_name}."/zipball/".$repo->{branch_name}
    );

    $download->authorization_basic($repo->{repo_user}, $repo->{repo_password});

    my $ua = LWP::UserAgent->new();

    my $zipfile = File::Temp->new( SUFFIX => '.zip', UNLINK => 1 );
    my $response = $ua->request($download, $zipfile->filename);

    if ($response->is_error) {
        die 'Could not download zipball: ' . $response->code . ' ' . $response->message;
    }

    if ($response->is_success) {
        my $extractor = Archive::Extract->new( archive => $zipfile->filename );
        $extractor->extract( to => File::Temp->newdir( CLEANUP => 0 ) );

        return $extractor->extract_path();
    }
}


1;
