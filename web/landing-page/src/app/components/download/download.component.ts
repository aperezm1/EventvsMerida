import { Component } from '@angular/core';
import { TranslatePipe } from '@ngx-translate/core';
import { RevealDirective } from '../../core/directives/reveal.directive';
import { DownloadAction } from '../../core/models/download-action.model';

/**
 * Componente de la sección Download.
 * Muestra las opciones de descarga, acceso al repositorio, código QR y footer de la landing.
 *
 * @author Eva Retamar
 * @author David Muñoz
 * @author Adrián Pérez
 */
@Component({
  selector: 'app-download',
  standalone: true,
  imports: [RevealDirective, TranslatePipe],
  templateUrl: './download.component.html',
  styleUrl: './download.component.scss'
})
export class DownloadComponent {
  readonly sectionId = 'download';

  readonly repoUrl = 'https://github.com/Null-Pointers-Albarregas/EventvsMerida';
  readonly apkUrl = 'https://eventvsmerida.vercel.app/downloads/eventvs-merida.apk';
  readonly adminUrl = 'https://eventvsmerida-admin.vercel.app';

  readonly labelKey = 'download.label';

  readonly titleLineKeys = {
    first: 'download.title.first',
    second: 'download.title.second'
  };

  readonly descriptionKey = 'download.description';

  readonly noteIcon = '⚠️';
  readonly noteTextKey = 'download.note.text';
  readonly noteStrongKey = 'download.note.strong';

  readonly qrCodeUrl = 'downloads/qr-code.png';
  readonly qrCodeAltKey = 'download.qrAlt';

  readonly footerCopyrightKey = 'download.footer.copyright';
  readonly footerLocationKey = 'download.footer.location';
  readonly adminAccessLabelKey = 'download.footer.adminAccess';
  readonly adminAccessAriaLabelKey = 'download.footer.adminAccessAriaLabel';

  readonly particles = [1, 2, 3, 4, 5, 6, 7, 8];

  readonly actions: DownloadAction[] = [
    {
      url: this.apkUrl,
      type: 'download',
      subtitleKey: 'download.actions.app.subtitle',
      titleKey: 'download.actions.app.title',
      buttonClass: 'dl-btn-primary'
    },
    {
      url: this.repoUrl,
      type: 'repository',
      subtitleKey: 'download.actions.repository.subtitle',
      titleKey: 'download.actions.repository.title',
      buttonClass: 'dl-btn-secondary'
    }
  ];
}
