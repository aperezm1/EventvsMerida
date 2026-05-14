import { DOCUMENT } from '@angular/common';
import {
  AfterViewInit,
  Component,
  ElementRef,
  inject,
  OnDestroy,
  ViewChild
} from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';
import { RevealDirective } from '../../core/directives/reveal.directive';
import { TeamMember } from '../../core/models/team-member.model';

/**
 * Componente de la sección Team.
 * Muestra los miembros del equipo, el enlace al centro educativo y una imagen con efecto parallax.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Component({
  selector: 'app-team',
  standalone: true,
  imports: [RevealDirective, TranslatePipe],
  templateUrl: './team.component.html',
  styleUrl: './team.component.scss'
})
export class TeamComponent implements AfterViewInit, OnDestroy {
  @ViewChild('teamPhoto', { static: true })
  private teamPhoto!: ElementRef<HTMLElement>;

  private readonly document = inject(DOCUMENT);
  private readonly parallaxLimit = 20;
  private readonly parallaxRange = 40;

  readonly sectionId = 'team';

  readonly labelKey = 'team.label';

  readonly titleLineKeys = {
    first: 'team.title.first',
    second: 'team.title.second'
  };

  readonly descriptionKey = 'team.description';

  readonly schoolBadgeIcon = '🏫';
  readonly schoolBadgeLabelKey = 'team.school.label';
  readonly schoolUrl = 'https://sites.google.com/iesalbarregas.es/portada/inicio';

  readonly photoUrl = 'assets/merida_letras.jpg';
  readonly photoAltKey = 'team.photoAlt';

  readonly members: TeamMember[] = [
    {
      name: 'Adrián Pérez Morales',
      roleKey: 'team.members.fullstackMale',
      imageUrl: 'assets/adrian.png',
      color: '#F5A623',
      url: 'https://github.com/aperezm1'
    },
    {
      name: 'David Muñoz Collado',
      roleKey: 'team.members.fullstackMale',
      imageUrl: 'assets/david.png',
      color: '#4299E1',
      url: 'https://github.com/dmunozc04-albarregas'
    },
    {
      name: 'Eva Retamar Muñoz',
      roleKey: 'team.members.fullstackFemale',
      imageUrl: 'assets/eva.png',
      color: '#68D391',
      url: 'https://github.com/Evaremu'
    }
  ];

  /**
   * Actualiza la posición de la imagen lateral para crear un efecto parallax suave.
   */
  private readonly scrollHandler = (): void => {
    const windowRef = this.document.defaultView;

    if (!windowRef) return;

    const rect = this.teamPhoto.nativeElement.getBoundingClientRect();
    const progress = (windowRef.innerHeight - rect.top) / (windowRef.innerHeight + rect.height);
    const offset = (progress - 0.5) * this.parallaxRange;
    const clampedOffset = Math.max(-this.parallaxLimit, Math.min(this.parallaxLimit, offset));

    this.teamPhoto.nativeElement.style.transform = `translateY(${clampedOffset}px)`;
  };

  /**
   * Registra el listener de scroll cuando la vista está inicializada.
   */
  ngAfterViewInit(): void {
    this.document.defaultView?.addEventListener('scroll', this.scrollHandler, {
      passive: true
    });

    this.scrollHandler();
  }

  /**
   * Elimina el listener de scroll al destruir el componente.
   */
  ngOnDestroy(): void {
    this.document.defaultView?.removeEventListener('scroll', this.scrollHandler);
  }
}
