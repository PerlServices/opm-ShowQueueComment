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

use Kernel::System::JSON;
use Kernel::System::Queue;

our $VERSION = 0.02;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (
        qw(MainObject ConfigObject LogObject LayoutObject ParamObject)
        )
    {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    $Self->{UserID} = $Param{UserID};

    $Self->{EncodeObject} = $Param{EncodeObject} || Kernel::System::Encode->new( %{$Self} );
    $Self->{TimeObject}   = $Param{TimeObject}   || Kernel::System::Time->new( %{$Self} );
    $Self->{JSONObject}   = $Param{JSONObject}   || Kernel::System::JSON->new( %{$Self} );
    $Self->{DBObject}     = $Self->{LayoutObject}->{DBObject};
    $Self->{QueueObject}  = $Param{QueueObject}   || Kernel::System::Queue->new( %{$Self} );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    # get template name
    my $Templatename = $Param{TemplateFile} || '';

    return 1 if !$Templatename;
    return 1 if !$Param{Templates}->{$Templatename};

    my %Queues = $Self->{QueueObject}->GetAllQueues(
        UserID => $Self->{UserID},
        Type   => 'create',
    );

    my $Mapping = {};

    for my $QueueID ( keys %Queues ) {
        my %QueueInfo = $Self->{QueueObject}->QueueGet(
            ID => $QueueID,
        );

        my $Key = sprintf "%s||%s", $QueueID, $QueueInfo{Name};
        $Mapping->{$Key} = $QueueInfo{Comment};
    }

    my $MappingJSON = $Self->{JSONObject}->Encode( Data => $Mapping );

    my $JS = qq~
        <!-- dtl:js_on_document_complete -->
            <script type="text/javascript">
                var queue_comments = $MappingJSON;
                \$('#Dest').bind('change', function() {
                    var parent_elem   = \$(this).closest('div');
                    var comment_div   = \$('#queue_comment');
                    var queue_comment = queue_comments[\$(this).val()] || '';
console.log( parent_elem );
console.log( comment_div );
console.log( queue_comment );

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
