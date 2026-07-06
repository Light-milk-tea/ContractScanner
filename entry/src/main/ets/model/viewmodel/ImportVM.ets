export class ImportVM {
  selectedFileName: string = ''
  selectedFileType: string = ''

  setSelectedFile(fileName: string, fileType: string): void {
    this.selectedFileName = fileName
    this.selectedFileType = fileType
  }

  reset(): void {
    this.selectedFileName = ''
    this.selectedFileType = ''
  }
}
