import { DOCUMENT } from '@angular/common';
import { Injectable, inject, signal } from '@angular/core';
import { TranslateService } from '@ngx-translate/core';
import { LanguageOption } from '../models/language-option.model';

/**
 * Servicio encargado de gestionar el idioma activo de la aplicación.
 * Centraliza los idiomas disponibles, la persistencia en localStorage y el cambio de idioma.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Injectable({
  providedIn: 'root'
})
export class LanguageService {
  private readonly document = inject(DOCUMENT);
  private readonly translateService = inject(TranslateService);

  private readonly defaultLanguage = 'es';
  private readonly languageStorageKey = 'eventvs-language';

  readonly languages: LanguageOption[] = [
    { code: 'es', labelKey: 'navbar.languages.es', flagUrl: 'assets/es.svg' },
    { code: 'en', labelKey: 'navbar.languages.en', flagUrl: 'assets/en.svg' },
    { code: 'pt', labelKey: 'navbar.languages.pt', flagUrl: 'assets/pt.svg' },
    { code: 'fr', labelKey: 'navbar.languages.fr', flagUrl: 'assets/fr.svg' }
  ];

  readonly currentLanguage = signal<string>(this.getInitialLanguage());

  constructor() {
    this.applyLanguage(this.currentLanguage());
  }

  /**
   * Cambia el idioma activo de la aplicación.
   */
  changeLanguage(language: string): void {
    if (!this.isSupportedLanguage(language)) {
      return;
    }

    this.currentLanguage.set(language);
    this.applyLanguage(language);
  }

  /**
   * Aplica el idioma en ngx-translate, en el atributo lang del HTML y en localStorage.
   */
  private applyLanguage(language: string): void {
    this.translateService.use(language);
    this.document.documentElement.lang = language;
    this.document.defaultView?.localStorage.setItem(this.languageStorageKey, language);
  }

  /**
   * Obtiene el idioma inicial desde localStorage, navegador o idioma por defecto.
   */
  private getInitialLanguage(): string {
    const savedLanguage = this.document.defaultView?.localStorage.getItem(this.languageStorageKey) ?? null;

    if (this.isSupportedLanguage(savedLanguage)) {
      return savedLanguage;
    }

    const browserLanguage = this.getBrowserLanguage();

    return this.isSupportedLanguage(browserLanguage)
      ? browserLanguage
      : this.defaultLanguage;
  }

  /**
   * Obtiene el idioma principal del navegador normalizado.
   */
  private getBrowserLanguage(): string | null {
    const windowRef = this.document.defaultView;

    if (!windowRef) {
      return null;
    }

    const browserLanguage =
      windowRef.navigator.languages?.[0] ?? windowRef.navigator.language ?? null;

    return browserLanguage?.split('-')[0].toLowerCase() ?? null;
  }

  /**
   * Comprueba si el idioma indicado está soportado por la aplicación.
   */
  private isSupportedLanguage(language: string | null): language is string {
    return this.languages.some((item) => item.code === language);
  }
}
