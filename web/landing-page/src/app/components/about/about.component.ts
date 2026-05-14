import { Component } from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';
import { RevealDirective } from '../../core/directives/reveal.directive';
import { AboutCard } from '../../core/models/about-card.model';
import { AboutStat } from '../../core/models/about-stat.model';

/**
 * Componente de la sección About.
 * Muestra la descripción principal del proyecto, estadísticas destacadas y tarjetas informativas.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Component({
  selector: 'app-about',
  standalone: true,
  imports: [RevealDirective, TranslatePipe],
  templateUrl: './about.component.html',
  styleUrl: './about.component.scss'
})
export class AboutComponent {
  readonly sectionId = 'about';

  readonly imageUrl = 'assets/merida_templo.jpg';
  readonly imageAltKey = 'about.imageAlt';

  readonly labelKey = 'about.label';

  readonly titleLineKeys = {
    first: 'about.title.first',
    second: 'about.title.second',
    third: 'about.title.third'
  };

  readonly paragraphKeys = [
    'about.paragraphs.first',
    'about.paragraphs.second'
  ];

  readonly stats: AboutStat[] = [
    {
      value: '1',
      labelKey: 'about.stats.oneApp'
    },
    {
      value: '∞',
      labelKey: 'about.stats.culturalEvents'
    },
    {
      value: '0',
      labelKey: 'about.stats.complications'
    }
  ];

  readonly cards: AboutCard[] = [
    {
      icon: '🏛️',
      titleKey: 'about.cards.heritage.title',
      descriptionKey: 'about.cards.heritage.description'
    },
    {
      icon: '🎭',
      titleKey: 'about.cards.culture.title',
      descriptionKey: 'about.cards.culture.description',
      offset: true,
      accentClass: 'accent-blue'
    }
  ];
}
