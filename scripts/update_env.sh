#!/bin/bash

# update the template and group IDs, if they exist - otherwise, leave them as they are
sed -i "s/exports\.SENDGRID_TEMPLATE_ID\( *\) = '\(.\+\)';/exports.SENDGRID_TEMPLATE_ID\1 = '${SENDGRID_TEMPLATE_ID:-\2}';/" /cocalc/src/smc-util/theme.js
sed -i "s/exports\.SENDGRID_ASM_INVITES\( *\) = \(.\+\);/exports.SENDGRID_ASM_INVITES\1 = ${SENDGRID_ASM_INVITES:-\2};/" /cocalc/src/smc-util/theme.js
sed -i "s/exports\.SENDGRID_ASM_NEWSLETTER\( *\) = \(.\+\);/exports.SENDGRID_ASM_NEWSLETTER\1 = ${SENDGRID_ASM_NEWSLETTER:-\2};/" /cocalc/src/smc-util/theme.js
