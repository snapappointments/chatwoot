<template>
  <aside class="sidebar animated shrink columns">
    <div class="logo">
      <router-link :to="dashboardPath" replace>
        <img :src="globalConfig.logo" :alt="globalConfig.installationName" />
      </router-link>
    </div>

    <div class="main-nav">
      <transition-group name="menu-list" tag="ul" class="menu vertical">
        <sidebar-item
          v-for="item in accessibleMenuItems"
          :key="item.toState"
          :menu-item="item"
        />
        <sidebar-item
          v-if="shouldShowInboxes"
          :key="inboxSection.toState"
          :menu-item="inboxSection"
        />
        <sidebar-item
          v-if="shouldShowInboxes"
          :key="labelSection.toState"
          :menu-item="labelSection"
        />
      </transition-group>
    </div>

    <div class="bottom-nav">
      <transition name="menu-slide">
        <div
          v-if="showOptionsMenu"
          v-on-clickaway="showOptions"
          class="dropdown-pane top"
        >
          <ul class="vertical dropdown menu">
            <li v-if="currentUser.accounts.length > 1">
              <button
                class="button clear change-accounts--button"
                @click="changeAccount"
              >
                {{ $t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS') }}
              </button>
            </li>
            <li>
              <router-link :to="`/app/accounts/${accountId}/profile/settings`">
                {{ $t('SIDEBAR_ITEMS.PROFILE_SETTINGS') }}
              </router-link>
            </li>
            <li>
              <a href="#" @click.prevent="logout()">
                {{ $t('SIDEBAR_ITEMS.LOGOUT') }}
              </a>
            </li>
          </ul>
        </div>
      </transition>
      <div class="current-user" @click.prevent="showOptions()">
        <thumbnail
          :src="currentUser.avatar_url"
          :username="currentUser.name"
          :status="currentUser.availability_status"
        />
        <div class="current-user--data">
          <h3 class="current-user--name">
            {{ currentUser.name }}
          </h3>
          <h5 class="current-user--role">
            {{ currentRole }}
          </h5>
        </div>
        <span class="current-user--options icon ion-android-more-vertical" />
      </div>
    </div>
    <woot-modal
      :show="showAccountModal"
      :on-close="onClose"
      class="account-selector--modal"
    >
      <woot-modal-header
        :header-title="$t('SIDEBAR_ITEMS.CHANGE_ACCOUNTS')"
        :header-content="$t('SIDEBAR_ITEMS.SELECTOR_SUBTITLE')"
      />
      <div
        v-for="account in currentUser.accounts"
        :key="account.id"
        class="account-selector"
      >
        <a :href="`/app/accounts/${account.id}/dashboard`">
          <i v-if="account.id === accountId" class="ion ion-ios-checkmark" />
          <label :for="account.name" class="account--details">
            <div class="account--name">{{ account.name }}</div>
            <div class="account--role">{{ account.role }}</div>
          </label>
        </a>
      </div>
    </woot-modal>
  </aside>
</template>

<script>
import { mapGetters } from 'vuex';
import { mixin as clickaway } from 'vue-clickaway';

import adminMixin from '../../mixins/isAdmin';
import Auth from '../../api/auth';
import SidebarItem from './SidebarItem';
import { frontendURL } from '../../helper/URLHelper';
import Thumbnail from '../widgets/Thumbnail';
import { getSidebarItems } from '../../i18n/default-sidebar';

export default {
  components: {
    SidebarItem,
    Thumbnail,
  },
  mixins: [clickaway, adminMixin],
  props: {
    route: {
      type: String,
      default: '',
    },
  },
  data() {
    return {
      showOptionsMenu: false,
      showAccountModal: false,
    };
  },
  computed: {
    ...mapGetters({
      currentUser: 'getCurrentUser',
      globalConfig: 'globalConfig/get',
      inboxes: 'inboxes/getInboxes',
      accountId: 'getCurrentAccountId',
      currentRole: 'getCurrentRole',
      accountLabels: 'labels/getLabelsOnSidebar',
    }),
    sidemenuItems() {
      return getSidebarItems(this.accountId);
    },
    accessibleMenuItems() {
      // get all keys in menuGroup
      const groupKey = Object.keys(this.sidemenuItems);

      let menuItems = [];
      // Iterate over menuGroup to find the correct group
      for (let i = 0; i < groupKey.length; i += 1) {
        const groupItem = this.sidemenuItems[groupKey[i]];
        // Check if current route is included
        const isRouteIncluded = groupItem.routes.includes(this.currentRoute);
        if (isRouteIncluded) {
          menuItems = Object.values(groupItem.menuItems);
        }
      }

      return this.filterMenuItemsByRole(menuItems);
    },
    currentRoute() {
      return this.$store.state.route.name;
    },
    shouldShowInboxes() {
      return this.sidemenuItems.common.routes.includes(this.currentRoute);
    },
    inboxSection() {
      return {
        icon: 'ion-folder',
        label: 'INBOXES',
        hasSubMenu: true,
        newLink: true,
        key: 'inbox',
        cssClass: 'menu-title align-justify',
        toState: frontendURL(`accounts/${this.accountId}/settings/inboxes`),
        toStateName: 'settings_inbox_list',
        children: this.inboxes.map(inbox => ({
          id: inbox.id,
          label: inbox.name,
          toState: frontendURL(`accounts/${this.accountId}/inbox/${inbox.id}`),
          type: inbox.channel_type,
        })),
      };
    },
    labelSection() {
      return {
        icon: 'ion-pound',
        label: 'LABELS',
        hasSubMenu: true,
        key: 'label',
        cssClass: 'menu-title align-justify',
        toState: frontendURL(`accounts/${this.accountId}/settings/labels`),
        toStateName: 'labels_list',
        children: this.accountLabels.map(label => ({
          id: label.id,
          label: label.title,
          color: label.color,
          toState: frontendURL(
            `accounts/${this.accountId}/label/${label.title}`
          ),
        })),
      };
    },
    dashboardPath() {
      return frontendURL(`accounts/${this.accountId}/dashboard`);
    },
  },
  mounted() {
    this.$store.dispatch('inboxes/get');
  },
  methods: {
    filterMenuItemsByRole(menuItems) {
      if (!this.currentRole) {
        return [];
      }
      return menuItems.filter(
        menuItem =>
          window.roleWiseRoutes[this.currentRole].indexOf(
            menuItem.toStateName
          ) > -1
      );
    },
    logout() {
      Auth.logout();
    },
    showOptions() {
      this.showOptionsMenu = !this.showOptionsMenu;
    },
    changeAccount() {
      this.showAccountModal = true;
    },
    onClose() {
      this.showAccountModal = false;
    },
  },
};
</script>

<style lang="scss">
@import '~dashboard/assets/scss/variables';

.account-selector--modal {
  .modal-container {
    width: 40rem;
  }

  .page-top-bar {
    padding-bottom: $space-two;
  }
}

.change-accounts--button.button {
  font-weight: $font-weight-normal;
  font-size: $font-size-small;
  padding: $space-small $space-one;
}

.dropdown-pane {
  li {
    a {
      padding: $space-small $space-one !important;
    }
  }
}

.account-selector {
  cursor: pointer;
  padding: $space-small $space-large;

  .ion-ios-checkmark {
    font-size: $font-size-big;

    & + .account--details {
      padding-left: $space-normal;
    }
  }

  .account--details {
    padding-left: $space-large + $space-smaller;
  }

  &:last-child {
    margin-bottom: $space-large;
  }

  a {
    align-items: center;
    cursor: pointer;
    display: flex;

    .account--name {
      cursor: pointer;
      font-size: $font-size-medium;
      font-weight: $font-weight-medium;
      line-height: 1;
    }

    .account--role {
      cursor: pointer;
      font-size: $font-size-mini;
      text-transform: capitalize;
    }
  }
}
</style>
