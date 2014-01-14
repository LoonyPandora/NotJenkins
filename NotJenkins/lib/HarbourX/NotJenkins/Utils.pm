package HarbourX::NotJenkins::Utils;

use common::sense;

use AnyEvent;
use AnyEvent::HTTP;
use Archive::Extract;
use Archive::Tar;
use Dancer ':syntax';
use Dancer::Plugin::Database;
use Data::Dump qw(dump);
use File::Find;
use File::Path;
use File::Slurp;
use File::Temp;
use Forks::Super;
use HTTP::Request;
use LWP;
use Promises qw(collect deferred);
use Future;
use Future::Utils qw(repeat_until_success);
use YAML::XS qw(LoadFile);




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



sub download_pull_request {
    my ($branch_name) = @_;

    my $project_sth = database->prepare(q{
        SELECT repo_name, repo_owner, repo_user, repo_password
        FROM projects
        WHERE enabled = 1
        LIMIT 1
    });

    $project_sth->execute();

    my $repo = $project_sth->fetchall_hashref([]);

    my $download = HTTP::Request->new(
        GET => "https://github.com/".$repo->{repo_owner}."/".$repo->{repo_name}."/zipball/".$branch_name
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





sub run_docker_tests {
    my ($repo_dir) = @_;

    my $config = LoadFile("$repo_dir/.leeroy.yml");

    my @commands = values %{$config->{tests}};
    for my $tests (@commands) {
        # my $cmd = join('; ', @$tests);

        # async_cmd($cmd);
        # say "CMD: $cmd = " . qx{$cmd};
    };

    # my @asdf = map { async_cmd( join('; ', @$_) ) } @commands;


    # die dump \@asdf;

    my $cv = AnyEvent->condvar;
 
    collect(
        map { async_cmd( join('; ', @$_) ) } @commands
    )->then(
        sub {
            $cv->send({
                output => \@_,
            });
        },
        sub { $cv->croak( 'ERROR' ) }
    );
 
    my $all_product_info = $cv->recv;

    return $all_product_info;
}





sub async_cmd {
    my ($cmd) = @_;

    my $d = deferred;

    fork {
        sub => sub {
            qx{$cmd};
            say "Running: $cmd";
        },
        callback => {
            finish => sub {
                $d->resolve( "DONE!" );
            },
            fail => sub {
                $d->reject( "FAILED!" )
            },
        }
    };

    return $d->promise;
}


1;
