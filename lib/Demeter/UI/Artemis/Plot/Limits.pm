package  Demeter::UI::Artemis::Plot::Limits;


=for Copyright
 .
 Copyright (c) 2006-2009 Bruce Ravel (bravel AT bnl DOT gov).
 All rights reserved.
 .
 This file is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself. See The Perl
 Artistic License.
 .
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

=cut

use Wx qw( :everything );
use base qw(Wx::Panel);
use Wx::Event qw(EVT_MENU EVT_CLOSE EVT_TOOL_ENTER EVT_CHECKBOX EVT_CHOICE EVT_ENTER_WINDOW EVT_LEAVE_WINDOW );
use Wx::Perl::TextValidator;

my $parts = ['Magnitude', 'Real part', 'Imaginary part'];
my $demeter = $Demeter::UI::Artemis::demeter;

sub new {
  my ($class, $parent) = @_;
  my $this = $class->SUPER::new($parent, -1, wxDefaultPosition, wxDefaultSize);

  my $szr = Wx::BoxSizer->new( wxVERTICAL );

  ## -------- plotting part for chi(R)
  my $hh = Wx::BoxSizer->new( wxHORIZONTAL );
  $szr  -> Add($hh, 0, wxALL, 5);
  my $label  = Wx::StaticText->new($this, -1, "Plot χ(R): ");
  $this->{rpart} = Wx::Choice->new($this, -1, wxDefaultPosition, wxDefaultSize, $parts);
  my $which = 0;
  ($which = 1) if ($demeter->co->default("plot", "r_pl") eq 'r');
  ($which = 2) if ($demeter->co->default("plot", "r_pl") eq 'i');
  $this->{rpart} -> Select($which);
  $hh -> Add($label, 0, wxLEFT|wxRIGHT, 5);
  $hh -> Add($this->{rpart}, 1, wxRIGHT, 5);

  ## -------- plotting part for chi(q)
  $hh   = Wx::BoxSizer->new( wxHORIZONTAL );
  $szr -> Add($hh, 0, wxALL, 5);
  my $label  = Wx::StaticText->new($this, -1, "Plot χ(q): ");
  $this->{qpart} = Wx::Choice->new($this, -1, wxDefaultPosition, wxDefaultSize, $parts);
  my $which = 1;
  ($which = 0) if ($demeter->co->default("plot", "q_pl") eq 'm');
  ($which = 2) if ($demeter->co->default("plot", "q_pl") eq 'i');
  $this->{qpart} -> Select($which);
  $hh -> Add($label, 0, wxLEFT|wxRIGHT, 5);
  $hh -> Add($this->{qpart}, 1, wxRIGHT, 5);

  $demeter->po->r_pl('m');
  $demeter->po->q_pl('r');
  EVT_CHOICE($this, $this->{rpart}, sub{OnChoice(@_, 'rpart', 'r_pl')});
  EVT_CHOICE($this, $this->{qpart}, sub{OnChoice(@_, 'qpart', 'q_pl')});
  $this->mouseover("rpart", "Choose the part of the complex χ(R) function to display when plotting the contents of the plotting list.");
  $this->mouseover("qpart", "Choose the part of the complex χ(q) function to display when plotting the contents of the plotting list.");

  ## -------- toggles for fit, win, bkg, res
  ##    after a fit: turn on fit toggle, bkg toggle is bkg refined
  my $gbs  =  Wx::GridBagSizer->new( 5,5 );
  $szr -> Add($gbs, 0, wxGROW|wxTOP|wxBOTTOM, 10);

  $this->{fit} = Wx::CheckBox->new($this, -1, "Plot fit");
  $gbs -> Add($this->{fit}, Wx::GBPosition->new(0,0));
  $demeter->po->plot_fit(0);
  $this->{background} = Wx::CheckBox->new($this, -1, "Plot bkg");
  $gbs -> Add($this->{background}, Wx::GBPosition->new(0,1));
  $demeter->po->plot_bkg(0);

  $this->{window} = Wx::CheckBox->new($this, -1, "Plot window");
  $gbs -> Add($this->{window}, Wx::GBPosition->new(1,0));
  $this->{window} -> SetValue(1);
  $demeter->po->plot_win(1);
  $this->{residual} = Wx::CheckBox->new($this, -1, "Plot residual");
  $gbs -> Add($this->{residual}, Wx::GBPosition->new(1,1));
  $demeter->po->plot_res(0);

  $this->{running} = Wx::CheckBox->new($this, -1, "Plot running R-factor");
  $gbs -> Add($this->{running}, Wx::GBPosition->new(2,0), Wx::GBSpan->new(1,2));
  $demeter->po->plot_run(0);

  EVT_CHECKBOX($this, $this->{fit},        sub{OnPlotToggle(@_, 'fit',        'plot_fit')});
  EVT_CHECKBOX($this, $this->{background}, sub{OnPlotToggle(@_, 'background', 'plot_bkg')});
  EVT_CHECKBOX($this, $this->{window},     sub{OnPlotToggle(@_, 'window',     'plot_win')});
  EVT_CHECKBOX($this, $this->{residual},   sub{OnPlotToggle(@_, 'residual',   'plot_res')});
  EVT_CHECKBOX($this, $this->{running},    sub{OnPlotToggle(@_, 'running',    'plot_run')});

  $this->mouseover("fit",        "Include the most recent fit when plotting a data set from the plotting list.");
  $this->mouseover("background", "Include the refined background when plotting a data set from the plotting list.");
  $this->mouseover("window",     "Include the most window function when making a plot from the plotting list.");
  $this->mouseover("residual",   "Include the residual of the most recent fit when plotting a data set from the plotting list.");
  $this->mouseover("residual",   "Include the running R-factor of the most recent fit when plotting a data set from the plotting list.");


  $szr -> Add(Wx::StaticLine->new($this, -1, wxDefaultPosition, wxDefaultSize, wxLI_HORIZONTAL), 0, wxGROW|wxLEFT|wxRIGHT, 5);

  ## -------- limits in k, R, and q
  $gbs  =  Wx::GridBagSizer->new( 10,5 );
  $szr -> Add($gbs, 0, wxGROW|wxTOP, 15);
  my %po;

  $label    = Wx::StaticText->new($this, -1, "kmin");
  $this->{kmin} = Wx::TextCtrl  ->new($this, -1, $demeter->co->default("plot", "kmin"),
				  wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,    Wx::GBPosition->new(0,1));
  $gbs     -> Add($this->{kmin}, Wx::GBPosition->new(0,2));
  $label    = Wx::StaticText->new($this, -1, "kmax");
  $this->{kmax} = Wx::TextCtrl  ->new($this, -1, $demeter->co->default("plot", "kmax"),
				  wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,    Wx::GBPosition->new(0,3));
  $gbs     -> Add($this->{kmax}, Wx::GBPosition->new(0,4));

  $label    = Wx::StaticText->new($this, -1, "rmin");
  $this->{rmin} = Wx::TextCtrl  ->new($this, -1, $demeter->co->default("plot", "rmin"),
				  wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,    Wx::GBPosition->new(1,1));
  $gbs     -> Add($this->{rmin}, Wx::GBPosition->new(1,2));
  $label    = Wx::StaticText->new($this, -1, "rmax");
  $this->{rmax} = Wx::TextCtrl  ->new($this, -1, $demeter->co->default("plot", "rmax"),
				  wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,    Wx::GBPosition->new(1,3));
  $gbs     -> Add($this->{rmax}, Wx::GBPosition->new(1,4));

  $label    = Wx::StaticText->new($this, -1, "qmin");
  $this->{qmin} = Wx::TextCtrl  ->new($this, -1, $demeter->co->default("plot", "qmin"),
				  wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,    Wx::GBPosition->new(2,1));
  $gbs     -> Add($this->{qmin}, Wx::GBPosition->new(2,2));
  $label    = Wx::StaticText->new($this, -1, "qmax");
  $this->{qmax} = Wx::TextCtrl  ->new($this, -1, $demeter->co->default("plot", "qmax"),
				  wxDefaultPosition, [50,-1]);
  $gbs     -> Add($label,    Wx::GBPosition->new(2,3));
  $gbs     -> Add($this->{qmax}, Wx::GBPosition->new(2,4));

  $this->{kmin} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{kmax} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{rmin} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{rmax} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{qmin} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );
  $this->{qmax} -> SetValidator( Wx::Perl::TextValidator->new( qr([0-9.]) ) );

  $this->mouseover("kmin", "The lower bound of a plot of χ(k).");
  $this->mouseover("kmax", "The upper bound of a plot of χ(k).");
  $this->mouseover("rmin", "The lower bound of a plot of χ(r).");
  $this->mouseover("rmax", "The upper bound of a plot of χ(r).");
  $this->mouseover("qmin", "The lower bound of a plot of χ(q).");
  $this->mouseover("qmax", "The upper bound of a plot of χ(q).");


  $this -> SetSizer($szr);
  return $this;
};

sub mouseover {
  my ($self, $widget, $text) = @_;
  my $sb = $Demeter::UI::Artemis::frames{main}->{statusbar};
  EVT_ENTER_WINDOW($self->{$widget}, sub{$sb->PushStatusText($text); $_[1]->Skip});
  EVT_LEAVE_WINDOW($self->{$widget}, sub{$sb->PopStatusText;         $_[1]->Skip});
};


sub OnPlotToggle {
  my ($this, $event, $button, $accessor) = @_;
  $demeter->po->$accessor($this->{$button}->GetValue);
  my $plotframe = $Demeter::UI::Artemis::frames{Plot};
  $plotframe->plot($event, $plotframe->{last});
};
sub OnChoice {
  my ($this, $event, $choice, $accessor) = @_;
  $demeter->po->$accessor(lc(substr($this->{$choice}->GetStringSelection, 0, 1)));
  my $plotframe = $Demeter::UI::Artemis::frames{Plot};
  my $space = substr($choice, 0, 1);
  $plotframe->plot($event, $space);
};

1;
