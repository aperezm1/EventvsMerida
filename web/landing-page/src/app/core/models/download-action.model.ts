export type DownloadActionType = 'download' | 'repository';

export interface DownloadAction {
  url: string;
  type: DownloadActionType;
  subtitleKey: string;
  titleKey: string;
  buttonClass: string;
}
