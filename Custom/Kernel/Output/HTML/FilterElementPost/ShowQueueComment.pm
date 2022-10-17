# --
# Copyright (C) 2014 - 2022 Perl-Services.de, https://www.perl-services.de/
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Output::HTML::FilterElementPost::ShowQueueComment;

use strict;
use warnings;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::System::JSON
    Kernel::System::Queue
);

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

    my $QueueObject  = $Kernel::OM->Get('Kernel::System::Queue');
    my $TicketObject = $Kernel::OM->Get('Kernel::System::Ticket');
    my $JSONObject   = $Kernel::OM->Get('Kernel::System::JSON');
    my $ParamObject  = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    if ( $Templatename eq 'AgentTicketZoom' ) {
        my $TicketID = $ParamObject->GetParam( Param => 'TicketID' );
        my %Ticket   = $TicketObject->TicketGet(
            TicketID => $TicketID,
            UserID   => $Self->{UserID},
        );

        my %QueueInfo = $QueueObject->QueueGet(
            ID => $Ticket{QueueID},
        );

        my $Comment = $QueueInfo{Comment} // '';
        my $Queue   = $Ticket{Queue};
        ${ $Param{Data} } =~ s{title="$Queue">$Queue\K}{<br>$Comment}xms;

        return 1;
    }

    my %Queues = $QueueObject->GetAllQueues(
        UserID => $Self->{UserID},
        Type   => 'create',
    );

    if ( !%Queues ) {
        %Queues = $QueueObject->GetAllQueues();
    }

    my $Mapping = {};

    for my $QueueID ( keys %Queues ) {
        my %QueueInfo = $QueueObject->QueueGet(
            ID => $QueueID,
        );

        my $Key = sprintf "%s||%s", $QueueID, $QueueInfo{Name};
        $Mapping->{$Key} = $QueueInfo{Comment};
    }

    my $MappingJSON = $JSONObject->Encode( Data => $Mapping );

    $LayoutObject->AddJSOnDocumentComplete(
        Code => qq~
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
        ~,
    );

    return 1;
}

1;
