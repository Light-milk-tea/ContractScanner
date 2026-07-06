export class ImportVM {
  selectedFileName: string = ''
  selectedFileType: string = ''
  selectedFileUri: string = ''
  selectedSource: string = 'LOCAL_FILE'

  setSelectedSource(source: string): void {
    this.selectedSource = source
  }

  setSelectedFile(fileName: string, fileType: string, fileUri: string): void {
    this.selectedFileName = fileName
    this.selectedFileType = fileType
    this.selectedFileUri = fileUri
  }

  reset(): void {
    this.selectedFileName = ''
    this.selectedFileType = ''
    this.selectedFileUri = ''
    this.selectedSource = 'LOCAL_FILE'
  }
}
