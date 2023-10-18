<div class="acp-page-container">
	<!-- IMPORT admin/partials/settings/header.tpl -->

	<div class="row m-0">
		<div id="spy-container" class="col-12 px-2 mb-4" tabindex="0">
			<form role="form" class="passkeys-settings clearfix">
				<div class="mb-4">
					<h5 class="fw-bold tracking-tight settings-header">[[passkeys:admin.pwdless-enforced-groups.title]]
					</h5>
					<div class="mb-3">
						<div class="form-group">
							<label for="pwdlessEnforcedGroups">[[passkeys:admin.pwdless-enforced-groups.help]]</label>
							<select class="form-select" id="pwdlessEnforcedGroups" name="pwdlessEnforcedGroups"
								multiple>
								<!-- BEGIN groups -->
								<option value="{../value}" {{{ if ../enabled }}}selected{{{ end }}}>{../name}</option>
								<!-- END groups -->
							</select>
						</div>
					</div>
				</div>
			</form>
		</div>
	</div>
</div>