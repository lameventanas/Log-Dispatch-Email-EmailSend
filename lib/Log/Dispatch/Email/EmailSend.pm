package Log::Dispatch::Email::EmailSend;

use strict;

use Log::Dispatch::Email;

use base qw( Log::Dispatch::Email );

use Email::Send 2.0;
use Email::Simple::Creator;

use Params::Validate qw(validate SCALAR ARRAYREF BOOLEAN);
Params::Validate::validation_options( allow_extra => 1 );

use vars qw[ $VERSION ];

$VERSION = 0.04;

1;

sub new {
    my $class = shift;
    my %p     = validate(
        @_,
        {
            mailer => {
                type    => SCALAR,
                default => 'Sendmail'
            },
            mailer_args => {
                type    => ARRAYREF,
                default => [],
            },
            send_args => {
                type    => ARRAYREF,
                default => [],
            },
        }
    );

    my $self = $class->SUPER::new(%p);

    if ( defined $p{send_args}[0] ) {

        # take first arg of send_args as mailer
        $self->{mailer} = splice( @{ $p{send_args} }, 0, 1 );
        $self->{mailer_args} = $p{send_args};
    }
    else {
        # backward compatibility with 0.03
        $self->{mailer}      = $p{mailer};
        $self->{mailer_args} = $p{mailer_args};
    }

    # not needed anymore
    delete $self->{send_args};

    $self->{to} = join ', ', @{ $self->{to} } if ref $self->{to};

    return $self;
}

sub send_email {
    my $self = shift;
    my %p    = @_;

    my $email = Email::Simple->create(
        header => [
            To      => $self->{to},
            From    => $self->{from},
            Subject => $self->{subject},
        ],
        body => $p{message},
    );

    my $sender = Email::Send->new( { mailer => $self->{mailer} } );
    $sender->mailer_args( $self->{mailer_args} );

    local $?;
    $sender->send($email);
}

__END__

=head1 NAME

Log::Dispatch::Email::EmailSend - Subclass of Log::Dispatch::Email that uses Email::Send

=head1 SYNOPSIS

  use Log::Dispatch::Email::EmailSend;

  my $email =
      Log::Dispatch::Email::EmailSend->new
          ( name        => 'email',
            min_level   => 'emerg',
            to          => [ qw( foo@bar.com bar@baz.org ) ],
            subject     => 'error',
	    send_args   => [ 'SMTP', Host => 'smtp.example.com', ssl => 1 ],
          );

  $email->log( message => 'Something bad is happening', level => 'emerg' );

=head1 DESCRIPTION

This is a subclass of Log::Dispatch::Email that implements the
send_email method using the Email::Send module.

=head1 METHODS

=over 4

=item * new

This method takes a hash of parameters.  The following options are
valid:

=over 8

=item * name ($)

The name of the object (not the filename!).  Required.

=item * min_level ($)

The minimum logging level this object will accept.  See the
Log::Dispatch documentation for more information.  Required.

=item * max_level ($)

The maximum logging level this obejct will accept.  See the
Log::Dispatch documentation for more information.  This is not
required.  By default the maximum is the highest possible level (which
means functionally that the object has no maximum).

=item * subject ($)

The subject of the email messages which are sent.  Defaults to "$0:
log email"

=item * to ($ or \@)

Either a string or a list reference of strings containing email
addresses.  Required.

=item * from ($)

A string containing an email address.  This is optional and may not
work with all mail sending methods.

=item * send_args (\@)

An array reference with the name of the C<Email::Send> mailer
to use when sending mail in the first position, followed by any
arguments to the mailer. By default 'Sendmail' is used
without any arguments.  This overrides mailer and mailer_args.

=item * mailer ($)

The name of the C<Email::Send> mailer to use when sending mail.
Kept for backwards compatibility with 0.03 and previous versions,
new code should use send_args.
Defaults to 'Sendmail.'

=item * mailer_args (\@)

An array reference containing additional arguments to be passed to the
mailer.
Kept for backwards compatibility with 0.03 and previous versions,
new code should use send_args.
By default, this is empty.

=item * buffered (0 or 1)

This determines whether the object sends one email per message it is
given or whether it stores them up and sends them all at once.  The
default is to buffer messages.

=item * callbacks( \& or [ \&, \&, ... ] )

This parameter may be a single subroutine reference or an array
reference of subroutine references.  These callbacks will be called in
the order they are given and passed a hash containing the following keys:

 ( message => $log_message, level => $log_level )

The callbacks are expected to modify the message and then return a
single scalar containing that modified message.  These callbacks will
be called when either the C<log> or C<log_to> methods are called and
will only be applied to a given message once.

=back

=item * log_message( level => $, message => $ )

Sends a message if the level is greater than or equal to the object's
minimum level.

=back

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 SEE ALSO

Log::Dispatch

=cut
