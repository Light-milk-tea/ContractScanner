import { Configuration, Want } from '@kit.AbilityKit'
import { formBindingData, FormExtensionAbility, formInfo } from '@kit.FormKit'
import { logError, logInfo } from '../common/logger'
import { CardService } from '../services/ability/CardService'

export default class EntryFormAbility extends FormExtensionAbility {
  cardService: CardService = new CardService()

  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = this.readFormId(want)
    this.registerAndRefreshForm(formId)
    logInfo(`Form added: ${formId}`, 'EntryFormAbility')
    return formBindingData.createFormBindingData(this.cardService.buildFormData(this.cardService.buildDefaultSnapshot()))
  }

  onUpdateForm(formId: string): void {
    this.refreshForm(formId)
  }

  onRemoveForm(formId: string): void {
    this.cardService.unregisterForm(this.context, formId).catch((error: Object) => {
      logError('Unregister form failed', JSON.stringify(error), 'EntryFormAbility')
    })
  }

  onChangeFormVisibility(newStatus: Record<string, number>): void {
    logInfo(`Form visibility changed: ${JSON.stringify(newStatus)}`, 'EntryFormAbility')
  }

  onConfigurationUpdate(config: Configuration): void {
    logInfo(`Form configuration updated: ${JSON.stringify(config)}`, 'EntryFormAbility')
  }

  readFormId(want: Want): string {
    if (want.parameters === undefined) {
      return ''
    }
    return want.parameters[formInfo.FormParam.IDENTITY_KEY] as string
  }

  registerAndRefreshForm(formId: string): void {
    if (formId.length === 0) {
      return
    }

    this.cardService.registerForm(this.context, formId)
      .then(() => {
        return this.cardService.refreshRegisteredForms(this.context)
      })
      .catch((error: Object) => {
        logError('Register form failed', JSON.stringify(error), 'EntryFormAbility')
      })
  }

  refreshForm(formId: string): void {
    this.cardService.registerForm(this.context, formId)
      .then(() => {
        return this.cardService.refreshRegisteredForms(this.context)
      })
      .catch((error: Object) => {
        logError('Refresh form failed', JSON.stringify(error), 'EntryFormAbility')
      })
  }
}
