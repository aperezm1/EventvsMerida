import { Directive, ElementRef, inject, Input, OnInit, OnDestroy } from '@angular/core';

/**
 * Directiva que aplica una animación de aparición al elemento
 * cuando entra en el viewport.
 *
 * Uso:
 * <div appReveal [revealDelay]="200" revealDirection="left"></div>
 * 
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Directive({
  selector: '[appReveal]',
  standalone: true
})
export class RevealDirective implements OnInit, OnDestroy {
  @Input() revealDelay: number = 0;
  @Input() revealDirection: 'up' | 'left' | 'right' | 'scale' = 'up';

  private observer?: IntersectionObserver;
  private el = inject(ElementRef);


  /**
   * Configura las clases iniciales y observa cuándo el elemento
   * entra o sale del viewport para mostrar u ocultar la animación.
   */
  ngOnInit() {
    const el = this.el.nativeElement as HTMLElement;

    el.classList.add('reveal');

    if (this.revealDirection === 'left') el.classList.add('from-left');
    if (this.revealDirection === 'right') el.classList.add('from-right');
    if (this.revealDirection === 'scale') el.classList.add('scale-in');
    if (this.revealDelay > 0) el.classList.add(`reveal-delay-${this.revealDelay}`);

    this.observer = new IntersectionObserver(
      ([entry]) => {
        if (entry.isIntersecting) {
          el.classList.add('visible');
          return;
        }

        el.classList.remove('visible');
      },
      { threshold: 0.15, rootMargin: '0px 0px -60px 0px' }
    );

    this.observer.observe(el);
  }


  /**
   * Limpia el observer al destruir la directiva.
   */
  ngOnDestroy() {
    this.observer?.disconnect();
  }
}
