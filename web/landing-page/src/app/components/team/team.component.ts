import { Component, ElementRef, OnDestroy, OnInit, ViewChild } from '@angular/core';
import { CommonModule } from '@angular/common';
import { RevealDirective } from '../../directives/reveal.directive';

interface Member {
  name: string;
  role: string;
  image: string;
  color: string;
  url: string;
}

@Component({
  selector: 'app-team',
  standalone: true,
  imports: [CommonModule, RevealDirective],
  templateUrl: './team.component.html',
  styleUrl: './team.component.scss'
})
export class TeamComponent implements OnInit, OnDestroy {
  @ViewChild('teamPhoto', { static: true }) teamPhoto!: ElementRef;

  private scrollHandler = () => {
    if (!this.teamPhoto?.nativeElement) {
      return;
    }

    const rect = this.teamPhoto.nativeElement.getBoundingClientRect();
    const windowHeight = window.innerHeight || 0;
    const progress = (windowHeight - rect.top) / (windowHeight + rect.height);
    const offset = (progress - 0.5) * 40;
    const clamped = Math.max(-20, Math.min(20, offset));
    this.teamPhoto.nativeElement.style.transform = `translateY(${clamped}px)`;
  };

  members: Member[] = [
    {
      name: 'Adrián Pérez Morales',
      role: 'Desarrollador FullStack',
      image: 'assets/adrian.png',
      color: '#F5A623',
      url: 'https://github.com/aperezm1'
    },
    {
      name: 'David Muñoz Collado',
      role: 'Desarrollador FullStack',
      image: 'assets/david.png',
      color: '#4299E1',
      url: 'https://github.com/dmunozc04-albarregas'
    },
    {
      name: 'Eva Retamar Muñoz',
      role: 'Desarrolladora FullStack',
      image: 'assets/eva.png',
      color: '#68D391',
      url: 'https://github.com/Evaremu'
    }
  ];
imgError: any;

  ngOnInit() {
    window.addEventListener('scroll', this.scrollHandler, { passive: true });
    this.scrollHandler();
  }

  ngOnDestroy() {
    window.removeEventListener('scroll', this.scrollHandler);
  }

}