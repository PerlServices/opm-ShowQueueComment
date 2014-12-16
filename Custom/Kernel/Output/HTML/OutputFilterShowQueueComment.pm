# --
# Kernel/Output/HTML/OutputFilterShowQueueComment.pm
# Copyright (C) 2014 Perl-Services.de, http://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::OutputFilterShowQueueComment;

use strict;
use warnings;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::System::JSON
    Kernel::System::Queue
);

our $VERSION = 0.02;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{UserID} = $Param{UserID};

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $Templatename = $Param{TemplateFile} || '';

    return 1 if !$Templatename;
    return 1 if !$Param{Templates}->{$Templatename};

    my $QueueObject = $Kernel::OM->Get('Kernel::System::Queue');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');

    my %Queues = $QueueObject->GetAllQueues(
        UserID => $Self->{UserID},
        Type   => 'create',
    );

    my $Mapping = {};

    for my $QueueID ( keys %Queues ) {
        my %QueueInfo = $QueueObject->QueueGet(
            ID => $QueueID,
        );

        my $Key = sprintf "%s||%s", $QueueID, $QueueInfo{Name};
        $Mapping->{$Key} = $QueueInfo{Comment};
    }

    my $MappingJSON = $JSONObject->Encode( Data => $Mapping );

    my $JS = qq~
        <!-- dtl:js_on_document_complete -->
            <script type="text/javascript">
                var queue_comments = $MappingJSON;
                \$('#Dest').bind('change', function() {
                    var parent_elem   = \$(this).closest('div');
                    var comment_div   = \$('#queue_comment');
                    var queue_comment = queue_comments[\$(this).val()] || '';

                    if ( comment_div.get(0) ) {
                        comment_div.text(queue_comment);
                    }
                    else {
                        var comment_div = \$('<div id="queue_comment">').text(queue_comment);
                        parent_elem.append( comment_div );
                    }
                });
            </script>
        <!-- dtl:js_on_document_complete -->
    ~;

    ${ $Param{Data} } =~ s{\z}{
        $JS
    }xms;


    return ${ $Param{Data} };
}

1;
