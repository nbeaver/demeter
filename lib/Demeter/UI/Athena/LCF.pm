package Demeter::UI::Athena::LCF;
use strict;
use warnings;

use Wx qw( :everything );
use base 'Wx::Panel';
use Wx::Event qw(EVT_BUTTON EVT_CHECKBOX EVT_COMBOBOX);

use Demeter::UI::Wx::SpecialCharacters qw(:all);

use vars qw($label);
$label = "Linear combination fitting";	# used in the Choicebox and in status bar messages to identify this tool

my $tcsize = [60,-1];

sub new {
  my ($class, $parent, $app) = @_;
  my $this = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize, wxMAXIMIZE_BOX );

  my $box = Wx::BoxSizer->new( wxVERTICAL);
  $this->{sizer}  = $box;

  my $hbox = Wx::BoxSizer->new( wxHORIZONTAL );
  $box->Add($hbox, 0, wxGROW|wxLEFT|wxRIGHT, 5);
  $hbox->Add(Wx::StaticText->new($this, -1, 'Fit range:'), 0, wxRIGHT|wxALIGN_CENTRE, 5);
  $this->{xmin} = Wx::TextCtrl->new($this, -1, -20, wxDefaultPosition, $tcsize);
  $hbox->Add($this->{xmin}, 0, wxLEFT|wxRIGHT|wxALIGN_CENTRE, 5);
  $hbox->Add(Wx::StaticText->new($this, -1, 'to'), 0, wxRIGHT|wxALIGN_CENTRE, 5);
  $this->{xmax} = Wx::TextCtrl->new($this, -1, 30, wxDefaultPosition, $tcsize);
  $hbox->Add($this->{xmax}, 0, wxLEFT|wxRIGHT|wxALIGN_CENTRE, 5);
  $this->{space} = Wx::RadioBox->new($this, -1, 'Fitting space', wxDefaultPosition, wxDefaultSize,
				     ["norm $MU(E)", "deriv $MU(E)", "$CHI(k)"],
				     1, wxRA_SPECIFY_ROWS);
  $hbox->Add($this->{space}, 0, wxLEFT|wxRIGHT|wxALIGN_CENTRE, 5);
  $this->{space}->SetSelection(0);

  $this->{notebook} = Wx::Notebook->new($this, -1, wxDefaultPosition, wxDefaultSize, wxNB_TOP);
  $box -> Add($this->{notebook}, 1, wxGROW|wxALL, 2);
  my $main  = $this->main_page($this->{notebook});
  my $fits  = $this->fit_page($this->{notebook});
  my $combi = $this->combi_page($this->{notebook});
  $this->{notebook} ->AddPage($main,  'Standards',     1);
  $this->{notebook} ->AddPage($fits,  'Fit results',   0);
  $this->{notebook} ->AddPage($combi, 'Combinatorics', 0);

  $this->{document} = Wx::Button->new($this, -1, 'Document section: linear combination fitting');
  $this->{return}   = Wx::Button->new($this, -1, 'Return to main window');
  $box -> Add($this->{$_}, 0, wxGROW|wxALL, 2) foreach (qw(document return));
  EVT_BUTTON($this, $this->{document}, sub{  $app->document("lcf")});
  EVT_BUTTON($this, $this->{return},   sub{  $app->{main}->{views}->SetSelection(0); $app->OnGroupSelect});

  $this->SetSizerAndFit($box);
  return $this;
};

sub main_page {
  my ($this, $nb) = @_;
  my $panel = Wx::Panel->new($nb, -1, wxDefaultPosition, wxDefaultSize, wxMAXIMIZE_BOX );
  my $box = Wx::BoxSizer->new( wxVERTICAL);

  my $hbox = Wx::BoxSizer->new( wxHORIZONTAL );
  $box -> Add($hbox, 0, wxALL|wxGROW, 5);
  $hbox->Add(Wx::StaticText->new($panel, -1, '       Standards', wxDefaultPosition, [180,-1]), 0, wxLEFT|wxRIGHT, 5);
  $hbox->Add(Wx::StaticText->new($panel, -1, 'Weight',   wxDefaultPosition, $tcsize), 0, wxLEFT|wxRIGHT, 10);
  $hbox->Add(Wx::StaticText->new($panel, -1, 'E0',), 0, wxLEFT|wxRIGHT, 10);
  $hbox->Add(Wx::StaticText->new($panel, -1, 'Fit E0'),   0, wxLEFT|wxRIGHT, 10);
  $hbox->Add(Wx::StaticText->new($panel, -1, 'Required'), 0, wxLEFT|wxRIGHT, 10);

  $this->{window} = Wx::ScrolledWindow->new($panel, -1, wxDefaultPosition, wxDefaultSize, wxVSCROLL);
  my $winbox  = Wx::GridBagSizer->new( 2,2 );
  $this->{window} -> SetSizer($winbox);
  $this->{window} -> SetScrollbars(0, 20, 0, 50);

  $this->{nstan} = 12;
  foreach my $i (0 .. $this->{nstan}-1) {
    $this->add_standard($this->{window}, $winbox, $i);
  };
  $box -> Add($this->{window}, 1, wxALL|wxGROW, 5);

  $hbox = Wx::BoxSizer->new( wxHORIZONTAL );
  $box -> Add($hbox, 2, wxLEFT|wxRIGHT|wxGROW, 5);

  my $optionsbox       = Wx::StaticBox->new($panel, -1, 'Options', wxDefaultPosition, wxDefaultSize);
  my $optionsboxsizer  = Wx::StaticBoxSizer->new( $optionsbox, wxVERTICAL );
  $hbox -> Add($optionsboxsizer, 1, wxGROW|wxALL, 5);
  $this->{components} = Wx::CheckBox->new($panel, -1, 'Plot weighted components');
  $this->{residual}   = Wx::CheckBox->new($panel, -1, 'Plot residual');
  $this->{linear}     = Wx::CheckBox->new($panel, -1, 'Add a linear term after E0');
  $this->{inclusive}  = Wx::CheckBox->new($panel, -1, 'All weights between 0 and 1');
  $this->{unity}      = Wx::CheckBox->new($panel, -1, 'Force weights to sum to 1');
  $this->{one_e0}     = Wx::CheckBox->new($panel, -1, 'All standards share an e0');
  $this->{usemarked}  = Wx::Button->new($panel, -1, 'Use marked groups');
  $optionsboxsizer->Add($this->{$_}, 0, wxGROW|wxALL, 1)
    foreach (qw(components residual linear inclusive unity one_e0 usemarked));
  $this->{$_} -> SetValue(0) foreach (qw(components residual linear one_e0));
  $this->{$_} -> SetValue(1) foreach (qw(inclusive unity));
  my $noisebox = Wx::BoxSizer->new( wxHORIZONTAL );
  $optionsboxsizer->Add($noisebox, 0, wxGROW|wxALL, 1);
  $noisebox->Add(Wx::StaticText->new($panel, -1, 'Add noise'), 0, wxRIGHT|wxALIGN_CENTRE, 5);
  $this->{noise} = Wx::TextCtrl->new($panel, -1, 0, wxDefaultPosition, $tcsize);
  $noisebox->Add($this->{noise}, 0, wxLEFT|wxRIGHT|wxALIGN_CENTRE, 5);
  $noisebox->Add(Wx::StaticText->new($panel, -1, 'to data'), 0, wxRIGHT|wxALIGN_CENTRE, 5);
  my $maxbox = Wx::BoxSizer->new( wxHORIZONTAL );
  $optionsboxsizer->Add($maxbox, 0, wxGROW|wxALL, 1);
  $maxbox->Add(Wx::StaticText->new($panel, -1, 'Use at most'), 0, wxRIGHT|wxALIGN_CENTRE, 5);
  $this->{max} = Wx::SpinCtrl->new($panel, -1, 4, wxDefaultPosition, $tcsize, wxSP_ARROW_KEYS, 2, 6);
  $maxbox->Add($this->{max}, 0, wxLEFT|wxRIGHT|wxALIGN_CENTRE, 5);
  $maxbox->Add(Wx::StaticText->new($panel, -1, 'standards'), 0, wxRIGHT|wxALIGN_CENTRE, 5);

  my $actionsbox       = Wx::StaticBox->new($panel, -1, 'Actions', wxDefaultPosition, wxDefaultSize);
  my $actionsboxsizer  = Wx::StaticBoxSizer->new( $actionsbox, wxVERTICAL );
  $hbox -> Add($actionsboxsizer, 1, wxGROW|wxALL, 5);
  $this->{fit}		 = Wx::Button->new($panel, -1, 'Fit this group');
  $this->{combi}	 = Wx::Button->new($panel, -1, 'Fit all combinations');
  $this->{fitmarked}	 = Wx::Button->new($panel, -1, 'Fit marked groups');
  $this->{report}	 = Wx::Button->new($panel, -1, 'Report for this group');
  $this->{markedreport}	 = Wx::Button->new($panel, -1, 'Marked fits report');
  $this->{plot}		 = Wx::Button->new($panel, -1, 'Plot data and sum');
  $this->{plotr}	 = Wx::Button->new($panel, -1, 'Plot data and sum in R');
  $this->{make}		 = Wx::Button->new($panel, -1, 'Make group from fit');
  foreach my $w (qw(fit combi fitmarked report markedreport plot plotr make)) {
    $actionsboxsizer->Add($this->{$w}, 0, wxGROW|wxALL, 0);
    $this->{$w}->Enable(0);
  };


  $panel->SetSizerAndFit($box);
  return $panel;
};

sub fit_page {
  my ($this, $nb) = @_;
  my $panel = Wx::Panel->new($nb, -1, wxDefaultPosition, wxDefaultSize, wxMAXIMIZE_BOX );
  my $box = Wx::BoxSizer->new( wxVERTICAL);

  $this->{result} = Wx::TextCtrl->new($panel, -1, q{}, wxDefaultPosition, wxDefaultSize,
				       wxTE_MULTILINE|wxTE_WORDWRAP|wxTE_AUTO_URL);
  $box->Add($this->{result}, 1, wxGROW|wxALL, 5);

  $this->{resultplot} = Wx::Button->new($panel, -1, 'Plot data and fit');
  $box->Add($this->{resultplot}, 0, wxGROW|wxALL, 5);
  $this->{resultreport} = Wx::Button->new($panel, -1, 'Write report for this fit');
  $box->Add($this->{resultreport}, 0, wxGROW|wxALL, 5);

  $panel->SetSizerAndFit($box);
  return $panel;
};

sub combi_page {
  my ($this, $nb) = @_;
  my $panel = Wx::Panel->new($nb, -1, wxDefaultPosition, wxDefaultSize, wxMAXIMIZE_BOX );
  my $box = Wx::BoxSizer->new( wxVERTICAL);
  $panel->SetSizerAndFit($box);
  return $panel;
};


sub add_standard {
  my ($this, $panel, $gbs, $i) = @_;
  my $box = Wx::BoxSizer->new( wxHORIZONTAL );
  $this->{'standard'.$i} = Demeter::UI::Athena::GroupList -> new($panel, $::app, 0, 0);
  $this->{'weight'.$i}   = Wx::TextCtrl -> new($panel, -1, 0, wxDefaultPosition, $tcsize);
  $this->{'e0'.$i}       = Wx::TextCtrl -> new($panel, -1, 0, wxDefaultPosition, $tcsize);
  $this->{'fite0'.$i}    = Wx::CheckBox -> new($panel, -1, q{ });
  $this->{'require'.$i}  = Wx::CheckBox -> new($panel, -1, q{ });
  $gbs -> Add(Wx::StaticText->new($panel, -1, sprintf("%2d: ",$i+1)), Wx::GBPosition->new($i,0));
  $gbs -> Add($this->{'standard'.$i}, Wx::GBPosition->new($i,1));
  $gbs -> Add($this->{'weight'.$i},   Wx::GBPosition->new($i,2));
  $gbs -> Add($this->{'e0'.$i},       Wx::GBPosition->new($i,3));
  $gbs -> Add($this->{'fite0'.$i},    Wx::GBPosition->new($i,4));
  $gbs -> Add($this->{'require'.$i},  Wx::GBPosition->new($i,5));
};

## deprecated?
sub pull_values {
  my ($this, $data) = @_;
  1;
};

## this subroutine fills the controls when an item is selected from the Group list
sub push_values {
  my ($this, $data) = @_;
  foreach my $i (0 .. $this->{nstan}-1) {
    $this->{'standard'.$i}->fill($::app, 0, 0)
  };
  1;
};

## this subroutine sets the enabled/frozen state of the controls
sub mode {
  my ($this, $data, $enabled, $frozen) = @_;
  1;
};

## yes, there is some overlap between what push_values and mode do.
## This separation was useful in Main.pm.  Some of the other tools
## make mode a null op.

1;


=head1 NAME

Demeter::UI::Athena::LCF - A linear combination fitting tool for Athena

=head1 VERSION

This documentation refers to Demeter version 0.4.

=head1 SYNOPSIS

This module provides a

=head1 CONFIGURATION


=head1 DEPENDENCIES

Demeter's dependencies are in the F<Bundle/DemeterBundle.pm> file.

=head1 BUGS AND LIMITATIONS

=over 4

=item *

This 'n' that

=back

Please report problems to Bruce Ravel (bravel AT bnl DOT gov)

Patches are welcome.

=head1 AUTHOR

Bruce Ravel (bravel AT bnl DOT gov)

L<http://cars9.uchicago.edu/~ravel/software/>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2006-2010 Bruce Ravel (bravel AT bnl DOT gov). All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlgpl>.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut