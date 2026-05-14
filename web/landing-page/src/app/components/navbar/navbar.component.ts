import { DOCUMENT } from '@angular/common';
import { Component, ElementRef, HostListener, computed, inject, signal } from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';
import { LanguageOption } from '../../core/models/language-option.model';
import { NavItem } from '../../core/models/nav-item.model';
import { LanguageService } from '../../core/services/language.service';

/**
 * Componente de barra de navegación.
 * Controla el estado del scroll, el menú móvil, el selector de idioma y la navegación suave entre secciones.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Component({
  selector: 'app-navbar',
  standalone: true,
  imports: [TranslatePipe],
  templateUrl: './navbar.component.html',
  styleUrl: './navbar.component.scss'
})
export class NavbarComponent {
  private readonly document = inject(DOCUMENT);
  private readonly elementRef = inject(ElementRef<HTMLElement>);
  private readonly languageService = inject(LanguageService);
  private readonly scrollLimit = 60;

  readonly logoUrl = 'assets/logo.jpeg';
  readonly logoAltKey = 'navbar.logoAlt';
  readonly languageSelectorLabelKey = 'navbar.languageSelectorLabel';

  readonly languages = this.languageService.languages;
  readonly currentLanguage = this.languageService.currentLanguage;
  readonly selectedLanguage = computed(() => this.getSelectedLanguage());

  readonly navItems: NavItem[] = [
    { labelKey: 'navbar.about', sectionId: 'about' },
    { labelKey: 'navbar.features', sectionId: 'features' },
    { labelKey: 'navbar.team', sectionId: 'team' },
    { labelKey: 'navbar.download', sectionId: 'download', cta: true }
  ];

  readonly mobileNavItems: NavItem[] = this.navItems.filter((item) => !item.cta);
  readonly mobileCtaItem: NavItem | undefined = this.navItems.find((item) => item.cta);

  readonly scrolled = signal(false);
  readonly menuOpen = signal(false);
  readonly languageMenuOpen = signal(false);

  /**
   * Actualiza el estado de la navbar cuando la ventana supera el límite de scroll.
   */
  @HostListener('window:scroll')
  onScroll(): void {
    const scrollY = this.document.defaultView?.scrollY ?? 0;
    this.scrolled.set(scrollY > this.scrollLimit);
  }

  /**
   * Cierra el menú de idiomas si se hace clic fuera del componente.
   */
  @HostListener('document:click', ['$event'])
  onDocumentClick(event: MouseEvent): void {
    const target = event.target as Node | null;

    if (target && !this.elementRef.nativeElement.contains(target)) {
      this.languageMenuOpen.set(false);
    }
  }

  /**
   * Abre o cierra el menú móvil.
   */
  toggleMenu(): void {
    this.menuOpen.update((open) => !open);
  }

  /**
   * Abre o cierra el selector de idioma.
   */
  toggleLanguageMenu(): void {
    this.languageMenuOpen.update((open) => !open);
  }

  /**
   * Selecciona un idioma desde el selector.
   */
  selectLanguage(language: LanguageOption, closeMenu = false): void {
    this.languageService.changeLanguage(language.code);
    this.languageMenuOpen.set(false);

    if (closeMenu) {
      this.menuOpen.set(false);
    }
  }

  /**
   * Desplaza la página suavemente hasta la sección indicada.
   */
  scrollTo(id: string): void {
    this.document.getElementById(id)?.scrollIntoView({ behavior: 'smooth' });
  }

  /**
   * Navega hasta una sección y cierra el menú móvil.
   */
  scrollToAndClose(id: string): void {
    this.scrollTo(id);
    this.menuOpen.set(false);
  }

  /**
   * Desplaza la página suavemente hasta el inicio.
   */
  scrollToTop(): void {
    this.document.defaultView?.scrollTo({ top: 0, behavior: 'smooth' });
  }

  /**
   * Obtiene la opción completa del idioma actualmente seleccionado.
   */
  private getSelectedLanguage(): LanguageOption {
    return this.languages.find((language) => language.code === this.currentLanguage()) ?? this.languages[0];
  }
}
