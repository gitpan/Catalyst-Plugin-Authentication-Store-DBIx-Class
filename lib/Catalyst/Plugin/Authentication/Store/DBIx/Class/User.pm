package Catalyst::Plugin::Authentication::Store::DBIx::Class::User;

use strict;
use warnings;
use base qw/Catalyst::Plugin::Authentication::User/;
use base qw/Class::Accessor::Fast/;

BEGIN {
    __PACKAGE__->mk_accessors(qw/config resultset _user _roles/);
}

sub new {
    my ( $class, $config, $c) = @_;

    my $self = {
        resultset => $c->model($config->{'user_class'}),
        config => $config,
        _roles => undef,
        _user => undef
    };
    
    bless $self, $class;
    

    if (!exists($self->config->{'id_field'})) {
        $self->config->{'id_field'} = 'id';
    }
    
    ## if we have lazyloading turned on - we should not query the DB unless something gets read.
    ## that's the idea anyway - still have to work out how to manage that - so for now we always force
    ## lazyload to off.
    $self->config->{lazyload} = 0;
    
#    if (!$self->config->{lazyload}) {
#        return $self->load_user($authinfo, $c);
#    } else {
#        ## what do we do with a lazyload?
#        ## presumably this is coming out of session storage.  
#        ## use $authinfo to fill in the user in that case?
#    }

    return $self;
}


sub load {
    my ($self, $authinfo, $c) = @_;
    
    my $dbix_class_config = 0;
    
    if (exists($authinfo->{'dbix_class'})) {
        $authinfo = $authinfo->{'dbix_class'};
        $dbix_class_config = 1;
    }
    
    ## User can provide an arrayref containing the arguments to search on the user class.
    ## or even provide a prepared resultset, allowing maximum flexibility for user retreival.
    ## these options are only available when using the dbix_class authinfo hash. 
    if ($dbix_class_config && exists($authinfo->{'resultset'})) {
        $self->_user($authinfo->{'resultset'}->first);
    } elsif ($dbix_class_config && exists($authinfo->{'searchargs'})) {
        $self->_user($self->resultset->search(@{$authinfo->{'searchargs'}})->first);    
    } else {
        ## merge the ignore fields array into a hash - so we can do an easy check while building the query
        my %ignorefields = map { $_ => 1} @{$self->config->{'ignore_fields_in_find'}};                                    
        my $searchargs = {};
        
        # now we walk all the fields passed in, and build up a search hash.
        foreach my $key (grep {!$ignorefields{$_}} keys %{$authinfo}) {
            if ($self->resultset->result_source->has_column($key)) {
                $searchargs->{$key} = $authinfo->{$key};
            }
        }
        $self->_user($self->resultset->search($searchargs)->first);
    }

    if ($self->get_object) {
        return $self;
    } else {
        return undef;
    }
    #$c->log->debug(dumper($self->{'user'}));

}

sub supported_features {
    my $self = shift;

    return {
        session         => 1,
        roles           => 1,
    };
}


sub roles {
    my ( $self ) = shift;
    ## this used to load @wantedroles - but that doesn't seem to be used by the roles plugin, so I dropped it.

    ## shortcut if we have already retrieved them
    if (ref $self->_roles eq 'ARRAY') {
        return(@{$self->_roles});
    }
    
    my @roles = ();
    if (exists($self->config->{'role_column'})) {
        @roles = split /[ ,\|]+/, $self->get($self->config->{'role_column'});
        $self->_roles(\@roles);
    } elsif (exists($self->config->{'role_relation'})) {
        my $relation = $self->config->{'role_relation'};
        if ($self->_user->$relation->result_source->has_column($self->config->{'role_field'})) {
            @roles = map { $_->get_column($self->config->{'role_field'}) } $self->_user->$relation->search(undef, { columns => [ $self->config->{'role_field'}]})->all();
            $self->_roles(\@roles);
        } else {
            Catalyst::Exception->throw("role table does not have a column called " . $self->config->{'role_field'});
        }
    } else {
        Catalyst::Exception->throw("user->roles accessed, but no role configuration found");
    }

    return @{$self->_roles};
}

sub for_session {
    my $self = shift;
    
    return $self->get($self->config->{'id_field'});
}

sub from_session {
    my ($self, $frozenuser, $c) = @_;
    
    # this could be a lot better.  But for now it just assumes $frozenuser is an id and uses find_user
    # XXX: hits the database on every request?  Not good...
    return $self->load( { $self->config->{'id_field'} => $frozenuser }, $c);
}

sub get {
    my ($self, $field) = @_;
    
    if ($self->_user->can($field)) {
        return $self->_user->$field;
    } else {
        return undef;
    }
}

sub get_object {
    my $self = shift;
    
    return $self->_user;
}

sub obj {
    my $self = shift;
    
    return $self->get_object;
}

sub AUTOLOAD {
    my $self = shift;
    (my $method) = (our $AUTOLOAD =~ /([^:]+)$/);
    return if $method eq "DESTROY";

    $self->_user->$method(@_);
}

1;
__END__

=head1 NAME

Catalyst::Plugin::Authentication::Store::DBIx::Class::User - The backing user
class for the Catalyst::Plugin::Authentication::Store::DBIx::Class storage
module.

=head1 VERSION

This documentation refers to version 0.02.

=head1 SYNOPSIS

Internal - not used directly, please see
L<Catalyst::Plugin::Authentication::Store::DBIx::Class> for details on how to
use this module. If you need more information than is present there, read the
source.

                

=head1 DESCRIPTION

The Catalyst::Plugin::Authentication::Store::DBIx::Class::User class implements user storage
connected to an underlying DBIx::Class schema object.

=head1 SUBROUTINES / METHODS

=head2 new 

Constructor.

=head2 load_user ( $authinfo, $c ) 

Retrieves a user from storage using the information provided in $authinfo.

=head2 supported_features

Indicates the features supported by this class.  These are currently Roles and Session.

=head2 roles

Returns an array of roles associated with this user, if roles are configured for this user class.

=head2 for_session

Returns a serialized user for storage in the session.  Currently, this is the value of the field
specified by the 'id_field' config variable.

=head2 get ( $fieldname )

Returns the value of $fieldname for the user in question.  Roughly translates to a call to 
the DBIx::Class::Row's get_column( $fieldname ) routine.

=head2 get_object 

Retrieves the DBIx::Class object that corresponds to this user

=head2 obj (method)

Synonym for get_object

=head1 BUGS AND LIMITATIONS

None known currently, please email the author if you find any.

=head1 AUTHOR

Jason Kuri (jk@domain.tld)

=head1 LICENSE

Copyright (c) 2007 the aforementioned authors. All rights
reserved. This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

=cut
