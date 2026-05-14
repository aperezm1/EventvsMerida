import { Component } from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';
import { RevealDirective } from '../../core/directives/reveal.directive';
import { FeatureImage } from '../../core/models/feature-image.model';
import { Feature } from '../../core/models/feature.model';

/**
 * Componente de la sección Features.
 * Muestra las funcionalidades principales de la aplicación junto a imágenes decorativas.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Component({
  selector: 'app-features',
  standalone: true,
  imports: [RevealDirective, TranslatePipe],
  templateUrl: './features.component.html',
  styleUrl: './features.component.scss'
})
export class FeaturesComponent {
  readonly sectionId = 'features';

  readonly labelKey = 'features.label';

  readonly titleLineKeys = {
    first: 'features.title.first',
    second: 'features.title.second'
  };

  readonly descriptionKey = 'features.description';

  readonly leftImage: FeatureImage = {
    url: 'assets/merida_teatro.webp',
    altKey: 'features.images.theatreAlt'
  };

  readonly rightImage: FeatureImage = {
    url: 'assets/merida_plaza.webp',
    altKey: 'features.images.squareAlt'
  };

  readonly features: Feature[] = [
    {
      icon: '🗺️',
      titleKey: 'features.items.map.title',
      descriptionKey: 'features.items.map.description'
    },
    {
      icon: '📅',
      titleKey: 'features.items.calendar.title',
      descriptionKey: 'features.items.calendar.description'
    },
    {
      icon: '🌍',
      titleKey: 'features.items.audience.title',
      descriptionKey: 'features.items.audience.description'
    },
    {
      icon: '🎫',
      titleKey: 'features.items.details.title',
      descriptionKey: 'features.items.details.description'
    },
    {
      icon: '🔍',
      titleKey: 'features.items.search.title',
      descriptionKey: 'features.items.search.description'
    }
  ];
}
