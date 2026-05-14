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
import { HeroAction } from '../../core/models/hero-action.model';

/**
 * Componente de la sección hero.
 * Gestiona el efecto parallax, los enlaces principales y la navegación hacia la sección About.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Component({
  selector: 'app-hero',
  standalone: true,
  imports: [RevealDirective, TranslatePipe],
  templateUrl: './hero.component.html',
  styleUrl: './hero.component.scss'
})
export class HeroComponent implements AfterViewInit, OnDestroy {
  @ViewChild('parallaxBg', { static: true })
  private parallaxBg!: ElementRef<HTMLElement>;

  private readonly document = inject(DOCUMENT);
  private readonly parallaxSpeed = 0.45;

  readonly locationLabelKey = 'hero.location';

  readonly titleLineKeys = {
    first: 'hero.title.first',
    second: 'hero.title.second',
    third: 'hero.title.third'
  };

  readonly subtitleLineKeys = {
    first: 'hero.subtitle.first',
    second: 'hero.subtitle.second'
  };

  readonly scrollHintTextKey = 'hero.scrollHint';

  readonly aboutSectionId = 'about';

  readonly qrCodeUrl = 'downloads/qr-code.png';
  readonly qrCodeAltKey = 'hero.qr.alt';

  readonly logoUrl = 'assets/logo.jpeg';
  readonly logoAltKey = 'hero.logoAlt';

  readonly particles = [1, 2, 3, 4, 5, 6, 7, 8];

  readonly heroActions: HeroAction[] = [
    {
      labelKey: 'hero.actions.download',
      url: 'https://eventvsmerida.vercel.app/downloads/eventvs-merida.apk',
      type: 'primary'
    },
    {
      labelKey: 'hero.actions.repository',
      url: 'https://github.com/Null-Pointers-Albarregas/EventvsMerida',
      type: 'secondary'
    }
  ];

  /**
   * Actualiza la posición del fondo para crear el efecto parallax.
   */
  private readonly scrollHandler = (): void => {
    const scrollY = this.document.defaultView?.scrollY ?? 0;

    this.parallaxBg.nativeElement.style.transform =
      `translateY(${scrollY * this.parallaxSpeed}px)`;
  };

  /**
   * Registra el listener de scroll cuando la vista ya está inicializada.
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

  /**
   * Desplaza la página suavemente hasta la sección About.
   */
  scrollToAbout(): void {
    this.document.getElementById(this.aboutSectionId)?.scrollIntoView({
      behavior: 'smooth'
    });
  }
}
