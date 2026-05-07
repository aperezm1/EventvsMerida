import { Component } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RevealDirective } from '../../directives/reveal.directive';

interface Member {
  name: string;
  role: string;
  image: string;
  color: string;
}

@Component({
  selector: 'app-team',
  standalone: true,
  imports: [CommonModule, RevealDirective],
  templateUrl: './team.component.html',
  styleUrl: './team.component.scss'
})
export class TeamComponent {

  members: Member[] = [
    {
      name: 'Adrián Pérez Morales',
      role: 'Desarrollador',
      image: 'assets/adrian.png',
      color: '#F5A623'
    },
    {
      name: 'David Muñoz Collado',
      role: 'Desarrollador',
      image: 'assets/david.png',
      color: '#4299E1'
    },
    {
      name: 'Eva Retamar Muñoz',
      role: 'Desarrolladora',
      image: 'assets/eva.png',
      color: '#68D391'
    }
  ];
imgError: any;

}