import { Component } from '@angular/core';
import { AboutComponent } from './components/about/about.component';
import { DownloadComponent } from './components/download/download.component';
import { FeaturesComponent } from './components/features/features.component';
import { HeroComponent } from './components/hero/hero.component';
import { NavbarComponent } from './components/navbar/navbar.component';
import { TeamComponent } from './components/team/team.component';

/**
 * Componente raíz de la aplicación.
 * Carga la estructura principal de la landing page mediante sus secciones.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    NavbarComponent,
    HeroComponent,
    AboutComponent,
    FeaturesComponent,
    TeamComponent,
    DownloadComponent
  ],
  templateUrl: './app.component.html'
})
export class AppComponent { }
