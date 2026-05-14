import { bootstrapApplication } from '@angular/platform-browser';

import { appConfig } from './app/app.config';
import { AppComponent } from './app/app.component';

/**
 * Punto de entrada principal de la aplicación.
 * Inicializa Angular cargando el componente raíz y la configuración global.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
bootstrapApplication(AppComponent, appConfig).catch((err) => console.error(err));
