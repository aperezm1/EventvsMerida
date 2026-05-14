import { DOCUMENT } from '@angular/common';
import { Component, HostListener, OnInit, inject, signal } from '@angular/core';
import { TranslatePipe, TranslateService } from '@ngx-translate/core';
import { LanguageOption } from '../../core/models/language-option.model';
import { NavItem } from '../../core/models/nav-item.model';

/**
 * Componente de barra de navegación.
 * Controla el estado del scroll, el menú móvil, el cambio de idioma y la navegación suave entre secciones.
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
export class NavbarComponent implements OnInit {
  private readonly document = inject(DOCUMENT);
  private readonly translateService = inject(TranslateService);
  private readonly scrollLimit = 60;
  private readonly languageStorageKey = 'eventvs-language';

  readonly logoUrl = 'assets/logo.jpeg';
  readonly logoAltKey = 'navbar.logoAlt';
  readonly languageSelectorLabelKey = 'navbar.languageSelectorLabel';

  readonly languages: LanguageOption[] = [
    { code: 'es', labelKey: 'navbar.languages.es' },
    { code: 'en', labelKey: 'navbar.languages.en' },
    { code: 'pt', labelKey: 'navbar.languages.pt' },
    { code: 'fr', labelKey: 'navbar.languages.fr' }
  ];

  readonly navItems: NavItem[] = [
    { labelKey: 'navbar.about', sectionId: 'about' },
    { labelKey: 'navbar.features', sectionId: 'features' },
    { labelKey: 'navbar.team', sectionId: 'team' },
    { labelKey: 'navbar.download', sectionId: 'download', cta: true }
  ];

  readonly mobileNavItems: NavItem[] = this.navItems.filter((item) => !item.cta);

  readonly scrolled = signal(false);
  readonly menuOpen = signal(false);
  readonly currentLanguage = signal('es');

  /**
   * Inicializa el idioma guardado o el idioma por defecto.
   */
  ngOnInit(): void {
    this.setInitialLanguage();
  }

  /**
   * Actualiza el estado de la navbar cuando la ventana supera el límite de scroll.
   */
  @HostListener('window:scroll')
  onScroll(): void {
    const scrollY = this.document.defaultView?.scrollY ?? 0;
    this.scrolled.set(scrollY > this.scrollLimit);
  }

  /**
   * Abre o cierra el menú móvil.
   */
  toggleMenu(): void {
    this.menuOpen.update((open) => !open);
  }

  /**
   * Cambia el idioma desde el selector desplegable.
   */
  changeLanguageFromSelect(event: Event, closeMenu = false): void {
    const language = (event.target as HTMLSelectElement).value;
    this.changeLanguage(language, closeMenu);
  }

  /**
   * Cambia el idioma activo de la aplicación.
   */
  changeLanguage(language: string, closeMenu = false): void {
    if (!this.isSupportedLanguage(language)) return;

    this.currentLanguage.set(language);
    this.translateService.use(language);
    this.document.documentElement.lang = language;
    this.document.defaultView?.localStorage.setItem(this.languageStorageKey, language);

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
 * Obtiene el idioma inicial desde localStorage o usa español por defecto.
 */
  private setInitialLanguage(): void {
    const savedLanguage =this.document.defaultView?.localStorage.getItem(this.languageStorageKey) ?? null;
    const language = this.isSupportedLanguage(savedLanguage) ? savedLanguage : 'es';

    this.changeLanguage(language);
  }

  /**
   * Comprueba si el idioma está soportado por la aplicación.
   */
  private isSupportedLanguage(language: string | null): language is string {
    return this.languages.some((item) => item.code === language);
  }
}
